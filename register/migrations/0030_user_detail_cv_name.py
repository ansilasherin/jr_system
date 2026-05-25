from django.db import migrations, models


def display_name_from_url(value):
    name = str(value).rstrip("/").split("/")[-1]
    stem, dot, extension = name.rpartition(".")
    if dot and len(stem) > 8 and stem[-8] == "_" and stem[-7:].isalnum():
        return f"{stem[:-8]}.{extension}"
    return name


def populate_cv_name(apps, schema_editor):
    User = apps.get_model("register", "user_detail")
    for user in User.objects.exclude(cv_url=""):
        if user.cv_name:
            continue
        user.cv_name = display_name_from_url(user.cv_url)
        user.save(update_fields=["cv_name"])


class Migration(migrations.Migration):
    dependencies = [
        ("register", "0029_seed_recommendation_jobs"),
    ]

    operations = [
        migrations.AddField(
            model_name="user_detail",
            name="cv_name",
            field=models.CharField(blank=True, default="", max_length=255),
        ),
        migrations.RunPython(populate_cv_name, migrations.RunPython.noop),
    ]
