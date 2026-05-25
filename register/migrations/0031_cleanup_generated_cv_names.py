from django.db import migrations


def clean_generated_cv_names(apps, schema_editor):
    User = apps.get_model("register", "user_detail")
    for user in User.objects.exclude(cv_name=""):
        stem, dot, extension = str(user.cv_name).rpartition(".")
        if dot and len(stem) > 8 and stem[-8] == "_" and stem[-7:].isalnum():
            user.cv_name = f"{stem[:-8]}.{extension}"
            user.save(update_fields=["cv_name"])


class Migration(migrations.Migration):
    dependencies = [
        ("register", "0030_user_detail_cv_name"),
    ]

    operations = [
        migrations.RunPython(clean_generated_cv_names, migrations.RunPython.noop),
    ]
