# 📦 UniManager Release Bundle — كيف تستخدم

## المحتوى

هذا الـ ZIP يحوي **النسخة الكاملة الجاهزة** من التطبيق:

- ✅ `index.html` — أحدث نسخة (splash screen، RTL fixes، saveState مُصلح)
- ✅ `sw.js` — Service Worker (CACHE_VERSION = v1.0.0 متطابق مع APP_VERSION)
- ✅ `manifest.json` — PWA manifest مع background_color = #0a0e17
- ✅ `icons/` — كل الأيقونات: icon-192/512، apple-touch، 12 splash للـ iOS
- ✅ `.github/workflows/` — 3 GitHub Actions (CI، Lighthouse، Deploy)
- ✅ `tools/` — scripts للفحوصات المحلية
- ✅ `package.json`, `.htmlvalidate.json`, `.stylelintrc.json`, `lighthouserc.cjs`
- ✅ `README.md`, `LICENSE`, `SETUP.md`, `docs/ARCHITECTURE.md`
- ✅ `.gitignore` (لا يدفع `node_modules/` وغيره)
- ✅ `setup.bat` و `setup.sh` — scripts الرفع التلقائي

## الخطوات (3 خطوات فقط)

### الخطوة 1 — فك الضغط

```bash
cd ~/Downloads
unzip unimanager-release.zip
```

سيُنشأ مجلد `unimanager/` فيه كل شيء.

### الخطوة 2 — انتقل للمجلد

```bash
cd unimanager
```

### الخطوة 3 — شغّل سكربت الرفع

**في Git Bash:**
```bash
bash setup.sh
```

**أو في Command Prompt (CMD) — انقر مزدوج على:**
```
setup.bat
```

السكربت سيعمل:
1. يضبط Git لشبكات متذبذبة (postBuffer كبير، HTTP/1.1، إلخ)
2. `git init` لو لم يكن مهيأ
3. يربط الريبو بـ origin
4. ينشئ commit واحد
5. `git push --force` (يستبدل النسخة الحالية على GitHub)

## بعد النجاح

سترى رسالة `SUCCESS — pushed to GitHub`. اذهب إلى:
```
https://github.com/andrewleko19-boop/unimanager
```

تأكد أنك ترى:
- `.github/` ✅
- `tools/` ✅
- `icons/` (15 ملف) ✅
- باقي الملفات

ثم:

1. **Settings → Pages → Source: GitHub Actions**
2. **Actions tab** — سترى أول CI run يبدأ تلقائياً
3. لو CI نجح، الـ deploy سيشتغل تلقائياً وينشر التطبيق

## لو السكربت طلب username/password

GitHub لم يعد يقبل password عادي. تحتاج Personal Access Token:

1. https://github.com/settings/tokens
2. **Generate new token (classic)**
3. صلاحيات: ✅ `repo` (الكامل)
4. أنشئ، انسخ الـ token
5. لمّا git يطلب password → الصق الـ token

## لو فشل الرفع رغم كل شيء

غيّر شبكتك:
- موبايل hotspot (4G أو 5G)
- شبكة جامعة (لو Wi-Fi البيت سيء)
- Cloudflare WARP (مجاني): https://1.1.1.1

ثم أعد تشغيل `setup.bat` / `setup.sh`.

---

## أسئلة شائعة

**هل سأخسر شيئاً على GitHub؟**
الـ force push سيستبدل كل شيء بمحتوى هذا الـ ZIP. لو في commits أو ملفات على GitHub لم تكن في الـ ZIP، ستضيع. لكن منذ ZIP فيه كل ما يهم، لا تقلق.

**ماذا لو فشل في منتصف الرفع؟**
أعد تشغيل `setup.bat` ببساطة. السكربت idempotent (يمكن تشغيله مرات بدون مشاكل).

**هل أحتاج أعمل `npm install` بعد الرفع؟**
لا. CI يعمل `npm install` تلقائياً على GitHub. أنت محلياً ما تحتاج إلا لو أردت تختبر `npm run check` على جهازك.
