# Adhan recordings

Each selectable recording has a stable app ID. Flutter uses the asset path for settings previews, and Android bundles a matching `res/raw` resource for offline prayer alarms.

| App resource ID | Arabic display name | Audio file |
| --- | --- | --- |
| `adhan_madinah` | أذان المدينة المنورة (التسجيل السابق) | Legacy Android resource; source asset is no longer present |
| `adhan_abdulbasit` | الشيخ عبد الباسط عبد الصمد | `عبدالباسط.mp3` |
| `adhan_makkah` | أذان مكة المكرمة | `مكة.mp3` |
| `adhan_madinah_new` | أذان المدينة المنورة | `اذان المدينة المنورة.mp3` |
| `adhan_mohamed_refaat` | الشيخ محمد رفعت | `اذان محمد رفعت.mp3` |
| `adhan_mahmoud_albanna` | الشيخ محمود علي البنا | `اذان محمود البنا.mp3` |
| `adhan_nasser_alqatami` | الشيخ ناصر القطامي | `اذان ناصر القطامي.mp3` |

The older `adhan_madinah` resource is retained so existing saved settings and native playback remain valid. New recordings are copied into Android raw resources; the supplied MP3 assets are left unchanged.
