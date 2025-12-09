from rest_framework import serializers
from .models import University, Document, AccessLog


class UniversitySerializer(serializers.ModelSerializer):
    document_count = serializers.SerializerMethodField()

    class Meta:
        model = University
        fields = [
            'id',
            'name',
            'code',
            'country',
            'is_active',
            'document_count',
            'created_at',
        ]

    def get_document_count(self, obj):
        return obj.documents.filter(status='PUBLISHED').count()


class DocumentListSerializer(serializers.ModelSerializer):
    university_name = serializers.CharField(source='university.name', read_only=True)
    uploaded_by_name = serializers.CharField(
        source='uploaded_by.get_full_name', read_only=True
    )

    class Meta:
        model = Document
        fields = [
            'id',
            'title',
            'type',
            'status',
            'authors',
            'publication_date',
            'university_name',
            'uploaded_by_name',
            'created_at',
            'file_size',
        ]


class DocumentDetailSerializer(serializers.ModelSerializer):
    university = UniversitySerializer(read_only=True)
    allowed_universities = UniversitySerializer(many=True, read_only=True)
    access_count = serializers.SerializerMethodField()
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = Document
        fields = '__all__'
        read_only_fields = ('uploaded_by', 'university')

    def get_access_count(self, obj):
        return obj.access_logs.count()

    def get_file_url(self, obj):
        request = self.context.get('request')
        if request and obj.file:
            return request.build_absolute_uri(obj.file.url)
        return None


class DocumentUploadSerializer(serializers.ModelSerializer):
    allowed_universities = serializers.PrimaryKeyRelatedField(
        many=True, queryset=University.objects.all(), required=False
    )

    class Meta:
        model = Document
        fields = [
            'id',
            'title',
            'type',
            'status',
            'abstract',
            'authors',
            'publication_date',
            'keywords',
            'file',
            'is_public',
            'allowed_universities',
        ]


class AccessLogSerializer(serializers.ModelSerializer):
    document_title = serializers.CharField(source='document.title', read_only=True)
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)

    class Meta:
        model = AccessLog
        fields = [
            'id',
            'document_title',
            'user_name',
            'ip_address',
            'accessed_at',
            'action',
        ]