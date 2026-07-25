# Onaylı Ekran Envanteri

Tüm APPROVED satırlarda `screen.png` ve `code.html` birlikte bulunur. `Marka/Dil` sütunundaki `PASS` TeknoAkış ve Türkçe uyumunu; `390` sütunundaki `PASS` açık 390 px container'ı, `RESP` responsive/mobile yapıyı belirtir. Flutter'da her ikisi de 360/390/430 testine tabidir.

| Durum | Ekran | Kaynak klasör | Yeni approved yolu | PNG | HTML | Sürüm | Marka/Dil | 390 | Görsel | Faz | Route | Not |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| APPROVED | Splash | `splash_ekran_teknoak` | `approved/authentication/splash_ekran_teknoak` | Var | Var | tek | PASS | 390 | OK | MVP | `/splash` | Başlangıç |
| APPROVED | Giriş | `giri_yap_teknoak` | `approved/authentication/giri_yap_teknoak` | Var | Var | tek | PASS | RESP | OK | V2 | `/login` | Faz 1 dışında |
| APPROVED | Hesap oluştur | `hesap_olu_tur_teknoak` | `approved/authentication/hesap_olu_tur_teknoak` | Var | Var | tek | PASS | RESP | OK | V2 | `/register` | Faz 1 dışında |
| APPROVED | Şifremi unuttum | `ifremi_unuttum_teknoak_fix` | `approved/authentication/ifremi_unuttum_teknoak_fix` | Var | Var | fix | PASS | RESP | OK | V2 | `/forgot-password` | Son düzeltme |
| APPROVED | E-posta doğrulama | `e_posta_do_rulama_teknoak` | `approved/authentication/e_posta_do_rulama_teknoak` | Var | Var | tek | PASS | RESP | OK | V2 | `/verify-email` | Faz 1 dışında |
| APPROVED | Misafir açıklaması | `misafir_kullan_c_a_klamas_teknoak` | `approved/authentication/misafir_kullan_c_a_klamas_teknoak` | Var | Var | tek | PASS | 390 | OK | V2 | `/guest-info` | Yerel açıklama |
| APPROVED | Oturum süresi doldu | `oturum_s_resi_doldu_teknoak` | `approved/authentication/oturum_s_resi_doldu_teknoak` | Var | Var | tek | PASS | 390 | OK | V2 | `/session-expired` | Sistem durumu |
| APPROVED | Onboarding 1 | `onboarding_1_ke_fet` | `approved/onboarding/onboarding_1_ke_fet` | Var | Var | tek | PASS | RESP | OK | MVP | `/onboarding/1` | Keşfet |
| APPROVED | Onboarding 2 | `onboarding_2_ki_iselle_tir` | `approved/onboarding/onboarding_2_ki_iselle_tir` | Var | Var | tek | PASS | RESP | OK | MVP | `/onboarding/2` | Kişiselleştir |
| APPROVED | Onboarding 3 | `onboarding_3_ba_lat` | `approved/onboarding/onboarding_3_ba_lat` | Var | Var | tek | PASS | RESP | OK | MVP | `/onboarding/3` | Başlat |
| APPROVED | İlgi alanı seçimi | `i_lgi_alan_se_imi_teknoak` | `approved/onboarding/i_lgi_alan_se_imi_teknoak` | Var | Var | tek | PASS | RESP | OK | MVP | `/interests` | Fixture seçim |
| APPROVED | Ana akış | `ana_ak_teknoak_unified` | `approved/feed/ana_ak_teknoak_unified` | Var | Var | unified | PASS | RESP | OK | MVP | `/home` | Ana referans |
| APPROVED | Akış yükleniyor | `ana_ak_y_kleniyor_teknoak` | `approved/feed/ana_ak_y_kleniyor_teknoak` | Var | Var | tek | PASS | RESP | OK | MVP | `/home?state=loading` | Skeleton |
| APPROVED | Boş ana akış | `bo_ana_ak_teknoak_final_fix` | `approved/feed/bo_ana_ak_teknoak_final_fix` | Var | Var | final_fix | PASS | 390 | OK | MVP | `/home?state=empty` | Son düzeltme |
| APPROVED | Keşfet | `ke_fet_teknoak` | `approved/explore/ke_fet_teknoak` | Var | Var | tek | PASS | RESP | OK | MVP | `/explore` | Ana sekme |
| APPROVED | Arama sonuçları | `arama_sonu_lar_teknoak_unified` | `approved/search/arama_sonu_lar_teknoak_unified` | Var | Var | unified | PASS | RESP | OK | V2 | `/search` | Son unified |
| APPROVED | Arama sonucu yok | `arama_sonucu_yok_teknoak` | `approved/search/arama_sonucu_yok_teknoak` | Var | Var | tek | PASS | RESP | OK | V2 | `/search?state=empty` | Empty state |
| APPROVED | GitHub repository detayı | `github_repo_detay_teknoak_unified` | `approved/repository/github_repo_detay_teknoak_unified` | Var | Var | unified | PASS | RESP | OK | MVP | `/repository/:id` | Fixture-only |
| APPROVED | Kaynak profili | `kaynak_profili_teknoak` | `approved/repository/kaynak_profili_teknoak` | Var | Var | tek | PASS | RESP | OK | V2 | `/source/:id` | Fixture-only |
| APPROVED | AI model detayı | `ai_model_detay_gemini_1.5_pro_unified` | `approved/ai_models/ai_model_detay_gemini_1.5_pro_unified` | Var | Var | unified | PASS | RESP | OK | MVP | `/ai-model/:id` | Veriler doğrulanmış değildir |
| APPROVED | Gönderi oluştur | `g_nderi_olu_tur_teknoak_fix` | `approved/social/g_nderi_olu_tur_teknoak_fix` | Var | Var | fix | PASS | RESP | OK | MVP | `/create-post` | Gerçek yayın yok |
| APPROVED | Gönderi detayı | `g_nderi_detay_teknoak` | `approved/social/g_nderi_detay_teknoak` | Var | Var | tek | PASS | RESP | OK | V2 | `/post/:id` | Fixture-only |
| APPROVED | Yorumlar | `yorumlar_teknoak` | `approved/social/yorumlar_teknoak` | Var | Var | tek | PASS | RESP | OK | V2 | `/post/:id/comments` | Gerçek gönderim yok |
| APPROVED | Yoruma yanıt | `yoruma_yan_t_verme_teknoak` | `approved/social/yoruma_yan_t_verme_teknoak` | Var | Var | tek | PASS | 390 | OK | V2 | `/comment/:id/reply` | Yerel form |
| APPROVED | Yorum düzenleme | `yorum_d_zenleme_teknoak` | `approved/social/yorum_d_zenleme_teknoak` | Var | Var | tek | PASS | 390 | OK | V2 | `/comment/:id/edit` | Yerel form |
| APPROVED | Yorum silme onayı | `yorum_silme_onay_teknoak` | `approved/social/yorum_silme_onay_teknoak` | Var | Var | tek | PASS | 390 | OK | V2 | dialog | Confirmation dialog |
| APPROVED | Koleksiyon listesi | `koleksiyon_listesi_teknoak_fix` | `approved/collections/koleksiyon_listesi_teknoak_fix` | Var | Var | fix | PASS | 390 | OK | V2 | `/collections` | Zorunlu Batch 02 |
| APPROVED | Koleksiyon detayı | `koleksiyon_detay_teknoak_v3` | `approved/collections/koleksiyon_detay_teknoak_v3` | Var | Var | v3 | PASS | 390 | OK | V2 | `/collections/:id` | Zorunlu Batch 02 |
| APPROVED | Yeni koleksiyon | `yeni_koleksiyon_olu_tur_teknoak` | `approved/collections/yeni_koleksiyon_olu_tur_teknoak` | Var | Var | tek | PASS | 390 | OK | V2 | `/collections/new` | Zorunlu Batch 02 |
| APPROVED | Kaydedilenler | `kaydedilenler_teknoak` | `approved/collections/kaydedilenler_teknoak` | Var | Var | tek | PASS | RESP | OK | V2 | `/saved` | Fixture-only |
| APPROVED | Bildirimler | `bildirimler_teknoak` | `approved/notifications/bildirimler_teknoak` | Var | Var | tek | PASS | RESP | OK | MVP | `/notifications` | Ana sekme |
| APPROVED | Bildirim yok | `bildirim_bulunamad_teknoak_fix` | `approved/notifications/bildirim_bulunamad_teknoak_fix` | Var | Var | fix | PASS | 390 | OK | MVP | `/notifications?state=empty` | Empty state |
| APPROVED | Bildirim izni kapalı | `bildirim_i_zni_kapal_teknoak` | `approved/notifications/bildirim_i_zni_kapal_teknoak` | Var | Var | tek | PASS | 390 | OK | V2 | `/notifications/permission` | Push yok |
| APPROVED | Bildirim tercihleri | `bildirim_tercihleri_teknoak` | `approved/notifications/bildirim_tercihleri_teknoak` | Var | Var | tek | PASS | RESP | OK | V2 | `/settings/notifications` | Yerel UI |
| APPROVED | Profil | `profil_teknoak` | `approved/profile/profil_teknoak` | Var | Var | tek | PASS | RESP | OK | MVP | `/profile` | Fixture profil |
| APPROVED | Takipçiler/takip edilenler | `takip_iler_ve_takip_edilenler` | `approved/profile/takip_iler_ve_takip_edilenler` | Var | Var | tek | PASS | RESP | OK | V2 | `/profile/follows` | Fixture-only |
| APPROVED | Ayarlar | `ayarlar_teknoak` | `approved/settings/ayarlar_teknoak` | Var | Var | tek | PASS | RESP | OK | MVP | `/settings` | Temel ayarlar |
| APPROVED | Dil ayarları | `dil_ayarlar_teknoak_fix` | `approved/settings/dil_ayarlar_teknoak_fix` | Var | Var | fix | PASS | 390 | OK | V2 | `/settings/language` | Zorunlu Batch 02 |
| APPROVED | Tema ayarları | `tema_ayarlar_teknoak` | `approved/settings/tema_ayarlar_teknoak` | Var | Var | tek | PASS | 390 | OK | V2 | `/settings/theme` | Zorunlu Batch 02 |
| APPROVED | İlgi alanlarını düzenle | `i_lgi_alanlar_d_zenleme_teknoak_v3_2` | `approved/settings/i_lgi_alanlar_d_zenleme_teknoak_v3_2` | Var | Var | v3_2 | PASS | 390 | OK | V2 | `/settings/interests` | Boş v3_1 reddedildi |
| APPROVED | Takip edilen kaynaklar | `takip_edilen_kaynaklar_teknoak_v3` | `approved/settings/takip_edilen_kaynaklar_teknoak_v3` | Var | Var | v3 | PASS | 390 | OK | V2 | `/settings/sources` | Zorunlu Batch 02 |
| APPROVED | Gizlilik | `gizlilik_ayarlar_teknoak` | `approved/settings/gizlilik_ayarlar_teknoak` | Var | Var | tek | PASS | 390 | OK | V2 | `/settings/privacy` | Zorunlu Batch 02 |
| APPROVED | Hesap silme | `hesap_silme_onay_teknoak` | `approved/settings/hesap_silme_onay_teknoak` | Var | Var | tek | PASS | 390 | OK | V2 | dialog | Gerçek silme yok |
| APPROVED | Çıkış onayı | `k_yapma_onay_teknoak_final_fix` | `approved/settings/k_yapma_onay_teknoak_final_fix` | Var | Var | final_fix | PASS | 390 | OK | V2 | dialog | Gerçek oturum yok |
| APPROVED | İnternet yok | `i_nternet_ba_lant_s_yok_teknoak_fix` | `approved/system_states/i_nternet_ba_lant_s_yok_teknoak_fix` | Var | Var | fix | PASS | 390 | OK | V2 | state | Zorunlu Batch 04 |
| APPROVED | Sunucu hatası | `sunucu_hatas_teknoak_fix` | `approved/system_states/sunucu_hatas_teknoak_fix` | Var | Var | fix | PASS | 390 | OK | V2 | state | Zorunlu Batch 04 |
| APPROVED | Bakım modu | `bak_m_modu_teknoak_fix` | `approved/system_states/bak_m_modu_teknoak_fix` | Var | Var | fix | PASS | 390 | OK | V2 | state | Zorunlu Batch 04 |
| APPROVED | Gönderi yayınlanamadı | `g_nderi_yay_nlanamad_teknoak_fix_2` | `approved/system_states/g_nderi_yay_nlanamad_teknoak_fix_2` | Var | Var | fix_2 | PASS | 390 | OK | V2 | dialog/state | fix_1 kullanılmaz |
| APPROVED | Yorum gönderilemedi | `yorum_g_nderilemedi_teknoak_fix` | `approved/system_states/yorum_g_nderilemedi_teknoak_fix` | Var | Var | fix | PASS | 390 | OK | V2 | dialog/state | Zorunlu Batch 04 |
| APPROVED | İçerik kaydedilemedi | `i_erik_kaydedilemedi_teknoak_fix` | `approved/system_states/i_erik_kaydedilemedi_teknoak_fix` | Var | Var | fix | PASS | 390 | OK | V2 | dialog/state | Zorunlu Batch 04 |
| APPROVED | Yenileme sınırı | `veri_yenileme_s_n_r_teknoak` | `approved/system_states/veri_yenileme_s_n_r_teknoak` | Var | Var | tek | PASS | 390 | OK | V2 | state | Canlı rate limit yok |
| APPROVED | Yetkisiz işlem | `yetkisiz_i_lem_teknoak_final_fix` | `approved/system_states/yetkisiz_i_lem_teknoak_final_fix` | Var | Var | final_fix | PASS | 390 | OK | V2 | state | Son düzeltme |
| APPROVED | Sistem durumu | `sistem_durumu_teknoak` | `approved/system_states/sistem_durumu_teknoak` | Var | Var | tek | PASS | RESP | OK | V2 | `/system-status` | Fixture-only |

## Açıkça reddedilen/arşivlenen seçimler

| Durum | Kaynak | Neden |
|---|---|---|
| BROKEN | `i_lgi_alanlar_d_zenleme_teknoak_v3_1` | HTML ana içerik ve alt eylem alanı boş; `v3_2` kullanıldı |
| ARCHIVED | `g_nderi_yay_nlanamad_teknoak_fix_1` | Eski sürüm; zorunlu `fix_2` kullanıldı |
| REJECTED | `ai_hub` ve diğer DevPulse/synthetic varyantlar | Marka/dil uyumsuzluğu |
| REJECTED | `devpulse_navigation_flow` | `screen.png` eksik |
| REJECTED | Görsel-only dört çıktı ve `logo` | `code.html` eksik; ekran çifti değil |
| POST_MVP | Repository/AI karşılaştırma ve sonuç paylaşma ekranları | Faz 1 kapsamı dışında |
| ARCHIVED | Diğer 50 eski sürüm | Daha yeni/tutarlı tam çift seçildi |

Arşivdeki tüm klasörler korunur ancak Flutter geliştirme referansı olarak kullanılmaz.

