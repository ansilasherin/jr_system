"""
URL configuration for jr_system project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path,include
from . import views
from django.conf.urls.static import static
from django.conf import settings

urlpatterns = [
    path('django-admin/',admin.site.urls),
    path('',include('register.urls')),
    path('accounts/', include('allauth.urls')),
    path('mcq_exam/', include('mcq_exam.urls')),
    path('m_test/', include('m_test.urls')),
    path('interview/', include('interview.urls')),
    path('ai_interview/', include('ai_interview.urls')),
    path('api/register/', include('register.api_urls')),
    path('api/mcq/', include('mcq_exam.api_urls')),
] + static(settings.MEDIA_URL, document_root = settings.MEDIA_ROOT)
