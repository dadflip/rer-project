from rest_framework.routers import DefaultRouter

from .views import DocumentViewSet, UniversityViewSet

router = DefaultRouter()
router.register(r'documents', DocumentViewSet, basename='document')
router.register(r'universities', UniversityViewSet, basename='university')

urlpatterns = router.urls

