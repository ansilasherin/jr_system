from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('register', '0016_application_hr_interview_date_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='job',
            name='department',
            field=models.CharField(max_length=100, blank=True, null=True),
        ),
    ]
