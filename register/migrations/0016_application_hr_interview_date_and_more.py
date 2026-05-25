import uuid
from django.db import migrations, models


def _populate_interview_room_id(apps, schema_editor):
    Application = apps.get_model('register', 'Application')
    for application in Application.objects.filter(interview_room_id__isnull=True):
        application.interview_room_id = uuid.uuid4()
        application.save(update_fields=['interview_room_id'])


class Migration(migrations.Migration):

    dependencies = [
        ('register', '0015_remove_jobprocess_interview_ended_at'),
    ]

    operations = [
        migrations.AddField(
            model_name='application',
            name='hr_interview_date',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='application',
            name='machine_test_date',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='application',
            name='mcq_date',
            field=models.DateTimeField(blank=True, null=True),
        ),

        # ✅ Add WITHOUT unique first
        migrations.AddField(
            model_name='application',
            name='interview_room_id',
            field=models.UUIDField(default=uuid.uuid4, editable=False),  # no unique yet
        ),

        # ✅ Give every existing row its own UUID in a DB-agnostic way
        migrations.RunPython(
            code=lambda apps, schema_editor: _populate_interview_room_id(apps, schema_editor),
            reverse_code=migrations.RunPython.noop,
        ),

        # ✅ Now safely add unique constraint
        migrations.AlterField(
            model_name='application',
            name='interview_room_id',
            field=models.UUIDField(default=uuid.uuid4, unique=True, editable=False),
        ),

        # ✅ Delete JobProcess last
        migrations.DeleteModel(
            name='JobProcess',
        ),
    ]