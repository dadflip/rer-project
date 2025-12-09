from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    """Utilisateur personnalisé avec profils"""
    
    ROLE_CHOICES = [
        ('ADMIN', 'Administrateur'),
        ('RESEARCHER', 'Chercheur'),
        ('STUDENT', 'Étudiant'),
        ('GUEST', 'Invité'),
    ]
    
    university = models.ForeignKey(
        'documents.University', 
        on_delete=models.SET_NULL, 
        null=True, 
        related_name='users'
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='GUEST')
    phone = models.CharField(max_length=20, blank=True)
    department = models.CharField(max_length=200, blank=True)
    bio = models.TextField(blank=True)
    
    # Permissions
    can_upload_documents = models.BooleanField(default=False)
    can_approve_documents = models.BooleanField(default=False)
    can_manage_users = models.BooleanField(default=False)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_login_ip = models.GenericIPAddressField(null=True, blank=True)
    
    class Meta:
        ordering = ['username']
    
    def __str__(self):
        return f"{self.get_full_name()} ({self.university})"