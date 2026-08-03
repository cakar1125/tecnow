# Pivot öncesi tasarım kopyası — **yürürlükte değil**

Bu klasör TeknoAkış **sosyal ağ** sürümünün tasarım devridir. Ürün hesapsız bir
teknoloji rehberine döndükten sonra buradaki ekranların çoğu **kaldırıldı**.

`approved/` altında bugün hâlâ şunlar duruyor:

| Klasör | Neden geçersiz |
|---|---|
| `authentication/` (`giri_yap`, `e_posta_do_rulama`) | **D-001** — hesap, kayıt, giriş yok |
| `social/` (`g_nderi_olu_tur`, `g_nderi_detay`) | **D-002** — kullanıcı gönderisi yok |
| `notifications/` | **D-006** — Bildirimler → Kaydedilenler |
| `profile/` | **D-006** — Profil → Ayarlar |

Klasör 1 Ağustos 2026'da `design_handoff/` adından çıkarıldı. Sebebi somut:
adı "design_handoff" olduğu ve içinde "approved" yazdığı için, depoya bakan
birinin (Claude, Codex ya da altı ay sonraki sen) **kaldırılmış sosyal
ekranları onaylı sanıp uygulaması** mümkündü.

## Yürürlükteki tasarım nerede

| Ne | Nerede |
|---|---|
| **Onaylı ekranlar + aktif harita** | `TeknoAkis_ClaudeCode_Handoff/design_handoff/` — `documentation/ACTIVE_SCREEN_MAP.md` yetkili listedir |
| **Ham Stitch export** | `claude3/stitch_techpulse_social (16)/` — salt okunur kaynak, 153 ekran |

Ölçüldü (2026-08-01): `ACTIVE_SCREEN_MAP.md`'nin saydığı 9 onaylı ekranın
**6'sı** bu kopyada hiç yok (`home`, `repository_detail`, `ai_model_detail`,
`project_assistant`, `saved`, `interests`). Yani bu klasör yalnız eski değil,
**eksik**.

## Neden silinmedi

Tarihsel karşılaştırma için duruyor: pivotta neyin değiştiğini görmek
gerekirse tek kaynak burası. Silmek yerine adlandırıldı.

Yeni arayüz çalışması (**D-014**) buradan değil, kullanıcının verdiği yeni
tasarımdan ve yukarıdaki iki yürürlükteki kaynaktan beslenir.
