# دليل تعبئة نموذج Data Safety في Play Console — UniManager

> هذا المستند هو الإجابات الجاهزة لنموذج **App content → Data safety** في Google Play Console،
> مشتقّة مما يجمعه التطبيق فعليًا (راجع `privacy.html` المنشورة على
> https://unimanager-sy.pages.dev/privacy.html). أسماء الخيارات مكتوبة بالإنجليزية
> **حرفيًا كما تظهر في النموذج** — اختر المطابق لها.

---

## 1) الأسئلة العامة (Overview)

| السؤال في النموذج | إجابتك |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (كل الاتصالات HTTPS/WSS) |
| Do you provide a way for users to request that their data is deleted? | **Yes** |

**ملاحظة مهمة عن «Shared»:** Supabase وSentry وGoogle يعملون كـ**Service Providers**
(يعالجون البيانات نيابةً عنك فقط)، وهذا **مستثنى من تعريف "Sharing"** في سياسة Play.
لذلك كل الفئات أدناه: **Collected = Yes, Shared = No**. لا إعلانات ولا بيع بيانات.

---

## 2) فئات البيانات (Data types) — حدّد التالية فقط

### Personal info
| النوع | Collected | Shared | Ephemeral | Required/Optional | Purposes |
|---|---|---|---|---|---|
| **Name** | Yes | No | No | Required | App functionality |
| **Email address** | Yes | No | No | Required | App functionality, Account management |

> المصدر: تسجيل الدخول بـGoogle (الاسم والبريد وصورة الملف من الملف الأساسي فقط).

### Photos and videos
| النوع | Collected | Shared | Ephemeral | Required/Optional | Purposes |
|---|---|---|---|---|---|
| **Photos** | Yes | No | No | **Optional** | App functionality |

> الصورة الرمزية وصورة المجموعة ومرفقات الصور في الشات — كلها باختيار المستخدم.

### Files and docs
| النوع | Collected | Shared | Ephemeral | Required/Optional | Purposes |
|---|---|---|---|---|---|
| **Files and docs** | Yes | No | No | **Optional** | App functionality |

> مرفقات الملفات (PDF/Office…) التي يرسلها المستخدم في شات المجموعة.

### Messages
| النوع | Collected | Shared | Ephemeral | Required/Optional | Purposes |
|---|---|---|---|---|---|
| **Other in-app messages** | Yes | No | No | **Optional** | App functionality |

> رسائل شات المجموعات (مرئية لأعضاء المجموعة فقط، محمية بـRLS).

### App activity
| النوع | Collected | Shared | Ephemeral | Required/Optional | Purposes |
|---|---|---|---|---|---|
| **Other user-generated content** | Yes | No | No | Required | App functionality |

> البيانات الأكاديمية التي يدخلها المستخدم: الجداول، المواد، الدرجات/المعدل،
> الامتحانات، المهام، الحضور، جلسات الدراسة، اختيار الجامعة.

### App info and performance
| النوع | Collected | Shared | Ephemeral | Required/Optional | Purposes |
|---|---|---|---|---|---|
| **Crash logs** | Yes | No | No | Optional | Analytics |
| **Diagnostics** | Yes | No | No | Optional | Analytics |

> عبر Sentry — رسائل الأخطاء ونوع الجهاز/المتصفح وإصدار التطبيق.
> عناوين البريد ورموز الدخول **تُنقّى تلقائيًا قبل الإرسال** (PII scrubbing).

### فئات **لا** تُحدَّد إطلاقًا (التطبيق لا يجمعها)
Location · Financial info · Health and fitness · Web browsing history ·
Contacts · Calendar · Audio files · Device or other IDs (للإعلانات) — **اتركها كلها فارغة**.

---

## 3) قسم Data security practices

| السؤال | الإجابة |
|---|---|
| Is data encrypted in transit? | **Yes** |
| Can users request data deletion? | **Yes** |

## 4) Account deletion (متطلب إلزامي للتطبيقات ذات الحسابات)

| الحقل | القيمة |
|---|---|
| Does your app allow users to create an account? | **Yes** (عبر Google Sign-In) |
| Account deletion URL | `https://unimanager-sy.pages.dev/privacy.html` |

> القسم §5 من سياسة الخصوصية يشرح آلية الحذف (مراسلة mh6127880@gmail.com من البريد
> المسجّل؛ يكتمل الحذف خلال 30 يومًا). **تحسين مستقبلي:** صفحة حذف ذاتي داخل التطبيق
> بدل البريد — Play يقبل الآلية الحالية ما دامت موثّقة وقابلة للتنفيذ.

## 5) أسئلة متفرقة قد تظهر في App content

| السؤال | الإجابة |
|---|---|
| Privacy policy URL | `https://unimanager-sy.pages.dev/privacy.html` |
| Ads — Does your app contain ads? | **No** |
| Target audience | 13+ (طلاب جامعات؛ ليس موجّهًا للأطفال) |
| News app? / COVID-19 app? / Government app? | No |
| Data deleted when user uninstalls? | البيانات المحلية نعم؛ بيانات الخادم تبقى حتى طلب الحذف (وضّحها هكذا إن سُئلت) |

---

*آخر تحديث: 10 يونيو 2026 — متزامن مع privacy.html (تاريخ السريان نفسه).*
