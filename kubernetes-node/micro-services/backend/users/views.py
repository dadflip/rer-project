from django.contrib.auth import get_user_model
from rest_framework import viewsets, permissions
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers import UserSerializer, AdminUserSerializer

User = get_user_model()


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.select_related('university').all()
    permission_classes = [permissions.IsAdminUser]

    def get_serializer_class(self):
        if self.request.user.is_staff:
            return AdminUserSerializer
        return UserSerializer

    def get_queryset(self):
        if self.request.user.is_staff:
            return self.queryset
        return User.objects.filter(id=self.request.user.id)


class CurrentUserView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

