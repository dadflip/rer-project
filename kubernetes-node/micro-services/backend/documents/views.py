import mimetypes
from pathlib import Path

from django.http import FileResponse, Http404
from django.db.models import Q, Count
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.parsers import JSONParser, MultiPartParser, FormParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import University, Document, AccessLog
from .serializers import (
    UniversitySerializer,
    DocumentListSerializer,
    DocumentDetailSerializer,
    DocumentUploadSerializer,
    AccessLogSerializer,
)


class UniversityViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = University.objects.filter(is_active=True)
    serializer_class = UniversitySerializer
    permission_classes = [IsAuthenticated]


class DocumentViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['type', 'status', 'university']
    search_fields = ['title', 'authors', 'keywords', 'abstract']
    ordering_fields = ['created_at', 'publication_date', 'title']
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def get_queryset(self):
        user = self.request.user

        if user.is_staff:
            return Document.objects.all()

        return (
            Document.objects.filter(
                Q(university=user.university)
                | Q(is_public=True)
                | Q(allowed_universities=user.university)
            )
            .distinct()
            .select_related('university', 'uploaded_by')
            .prefetch_related('allowed_universities')
        )

    def get_serializer_class(self):
        if self.action == 'list':
            return DocumentListSerializer
        if self.action in ['upload', 'create']:
            return DocumentUploadSerializer
        if self.action == 'log_access':
            return AccessLogSerializer
        return DocumentDetailSerializer

    def perform_create(self, serializer):
        document = serializer.save(
            uploaded_by=self.request.user,
            university=self.request.user.university,
        )
        self._set_file_metadata(document)

    def _set_file_metadata(self, document: Document) -> None:
        if not document.file:
            return
        document.file_size = document.file.size
        guess = mimetypes.guess_type(document.file.name)[0]
        document.mime_type = guess or 'application/octet-stream'
        document.save(update_fields=['file_size', 'mime_type'])

    @action(detail=True, methods=['post'])
    def log_access(self, request, pk=None):
        document = self.get_object()

        AccessLog.objects.create(
            document=document,
            user=request.user,
            university=request.user.university,
            ip_address=self.get_client_ip(request),
            action=request.data.get('action', 'VIEW'),
        )

        return Response({'status': 'access logged'})

    @action(detail=False, methods=['get'], url_path='stats')
    def stats(self, request):
        queryset = self.get_queryset()

        stats = {
            'total': queryset.count(),
            'by_type': queryset.values('type').annotate(count=Count('id')),
            'by_university': queryset.values('university__code').annotate(count=Count('id')),
            'recent': list(
                queryset.order_by('-created_at')[:10].values('id', 'title', 'created_at')
            ),
            'views': AccessLog.objects.filter(action='VIEW').count(),
            'downloads': AccessLog.objects.filter(action='DOWNLOAD').count(),
        }
        return Response(stats)

    @action(detail=True, methods=['get'], url_path='download')
    def download(self, request, pk=None):
        document = self.get_object()
        if not document.file:
            raise Http404('File not found')

        file_path = Path(document.file.path)
        if not file_path.exists():
            raise Http404('File missing on server')

        AccessLog.objects.create(
            document=document,
            user=request.user,
            university=request.user.university,
            ip_address=self.get_client_ip(request),
            action='DOWNLOAD',
        )

        response = FileResponse(open(file_path, 'rb'), as_attachment=True)
        response['Content-Type'] = document.mime_type or 'application/octet-stream'
        response['Content-Length'] = document.file_size or file_path.stat().st_size
        response['Content-Disposition'] = f'attachment; filename="{file_path.name}"'
        return response

    @action(detail=False, methods=['post'], url_path='upload', parser_classes=[MultiPartParser, FormParser])
    def upload(self, request):
        serializer = DocumentUploadSerializer(
            data=request.data, context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        document = serializer.save(
            uploaded_by=request.user,
            university=request.user.university,
        )
        self._set_file_metadata(document)
        read_serializer = DocumentDetailSerializer(
            document, context={'request': request}
        )
        return Response(read_serializer.data, status=status.HTTP_201_CREATED)

    def get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0]
        return request.META.get('REMOTE_ADDR')