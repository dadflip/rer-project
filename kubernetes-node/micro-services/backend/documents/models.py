from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class University(models.Model):
    """Universités membres du RER"""
    name = models.CharField(max_length=200)
    code = models.CharField(max_length=10, unique=True)
    country = models.CharField(max_length=100)
    vpn_ip = models.GenericIPAddressField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name_plural = "Universities"
        ordering = ['name']
    
    def __str__(self):
        return f"{self.name} ({self.code})"

class Document(models.Model):
    """Documents scientifiques et pédagogiques"""

    TYPE_CHOICES = [
        ('ARTICLE', 'Article scientifique'),
        ('THESIS', 'Thèse'),
        ('COURSE', 'Cours'),
        ('REPORT', 'Rapport de recherche'),
        ('BOOK', 'Livre'),
        ('OTHER', 'Autre'),
    ]

    STATUS_CHOICES = [
        ('DRAFT', 'Brouillon'),
        ('PUBLISHED', 'Publié'),
        ('ARCHIVED', 'Archivé'),
    ]

    title = models.CharField(max_length=500)
    type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='DRAFT')
    abstract = models.TextField(blank=True)
    authors = models.TextField()
    publication_date = models.DateField(null=True, blank=True)
    keywords = models.TextField(blank=True)

    # Métadonnées
    university = models.ForeignKey(
        University, on_delete=models.CASCADE, related_name='documents'
    )
    uploaded_by = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, related_name='uploaded_documents'
    )
    file = models.FileField(upload_to='documents/')
    file_size = models.BigIntegerField(blank=True, null=True)
    mime_type = models.CharField(max_length=100, blank=True)

    # Permissions
    is_public = models.BooleanField(default=False)
    allowed_universities = models.ManyToManyField(
        University, related_name='accessible_documents', blank=True
    )

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['type', 'status']),
            models.Index(fields=['university', 'created_at']),
        ]

    def __str__(self):
        return self.title

class AccessLog(models.Model):
    """Logs d'accès aux documents"""
    document = models.ForeignKey(Document, on_delete=models.CASCADE, related_name='access_logs')
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    university = models.ForeignKey(University, on_delete=models.SET_NULL, null=True)
    ip_address = models.GenericIPAddressField()
    accessed_at = models.DateTimeField(auto_now_add=True)
    action = models.CharField(max_length=50)  # VIEW, DOWNLOAD, EDIT
    
    class Meta:
        ordering = ['-accessed_at']