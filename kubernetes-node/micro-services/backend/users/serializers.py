from django.contrib.auth import get_user_model
from rest_framework import serializers

from documents.serializers import UniversitySerializer
from documents.models import University

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    university = UniversitySerializer(read_only=True)
    university_id = serializers.PrimaryKeyRelatedField(
        source='university', queryset=University.objects.all(), write_only=True
    )

    class Meta:
        model = User
        fields = [
            'id',
            'username',
            'first_name',
            'last_name',
            'email',
            'role',
            'phone',
            'department',
            'bio',
            'university',
            'university_id',
            'can_upload_documents',
            'can_approve_documents',
            'can_manage_users',
            'is_staff',
            'is_active',
            'created_at',
            'updated_at',
        ]
        read_only_fields = (
            'can_upload_documents',
            'can_approve_documents',
            'can_manage_users',
            'created_at',
            'updated_at',
        )


class AdminUserSerializer(UserSerializer):
    password = serializers.CharField(write_only=True, required=False)

    class Meta(UserSerializer.Meta):
        fields = UserSerializer.Meta.fields + ['password']
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        password = validated_data.pop('password', None)
        user = super().create(validated_data)
        if password:
            user.set_password(password)
            user.save(update_fields=['password'])
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        user = super().update(instance, validated_data)
        if password:
            user.set_password(password)
            user.save(update_fields=['password'])
        return user

