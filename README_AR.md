# Pet World — GitHub + Supabase

هذه حزمة تجهيز لنشر موقع Pet World على GitHub Pages وربطه لاحقًا بقاعدة بيانات Supabase.

## قبل النشر
- `index.html` هو ملف الموقع الحالي.
- `supabase_schema.sql` ينشئ جداول المنتجات والطلبات.
- **مهم:** الموقع الحالي ما زال يحفظ المنتجات والطلبات في `localStorage`. إنشاء الجداول وحده لا يربط الموقع تلقائيًا بها. يجب إضافة إعدادات مشروع Supabase وتعديل وظائف القراءة/الحفظ، ثم تأمين لوحة الأدمن بتسجيل دخول Supabase Auth قبل السماح بتعديل المنتجات أو قراءة الطلبات.
- لا تضع `service_role` key في ملفات الموقع أبدًا. استخدم anon/publishable key فقط مع سياسات RLS.

## رفع الملفات على GitHub من الموبايل
1. افتح https://github.com وسجّل الدخول.
2. اضغط `+` ثم `New repository`.
3. سمِّ المستودع `pet-world-website` واختر `Public` ثم `Create repository`.
4. اضغط `Add file` ثم `Upload files`.
5. ارفع `index.html` و`supabase_schema.sql` و`README_AR.md` من هذه الحزمة، ثم اضغط `Commit changes`.
6. من `Settings` ثم `Pages` اختر `Deploy from a branch`، ثم `main` و`/ (root)` واضغط `Save`.
7. انتظر ظهور رابط الموقع في صفحة Pages.

## إنشاء قاعدة البيانات
1. افتح https://supabase.com وأنشئ مشروعًا جديدًا.
2. من `SQL Editor` اختر `New query`.
3. انسخ محتوى `supabase_schema.sql` والصقه ثم اضغط `Run`.
4. بعد ذلك يلزم توصيل الموقع فعليًا بواجهة Supabase وإعداد تسجيل دخول آمن للأدمن. لا تُفعّل سياسات تسمح لأي زائر بتعديل المنتجات أو قراءة بيانات العملاء.

## ملاحظات
- الكاميرا تحتاج رابط HTTPS؛ GitHub Pages يوفر HTTPS.
- لا ترفع مفاتيح سرية أو كلمات مرور في المستودع.
- كلمة مرور الأدمن الحالية داخل الواجهة فقط، لذلك ليست حماية حقيقية قبل نقل الدخول إلى Supabase Auth.
