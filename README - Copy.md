Mevcut Diller: [English](README.md) | [Türkçe](README_TR.md)

# 🌻 SunflowerBot: FPGA Tabanlı Otonom Güneş Takip Sistemi

![demo](https://github.com/user-attachments/assets/1536b20f-7956-42f9-8431-87e7970cd9c4)  
*Şekil 1. SunflowerBot sisteminin gerçek zamanlı çalışma gösterimi*

![Durum](https://img.shields.io/badge/Durum-Tamamlandı-success)
![Yazılım Dili](https://img.shields.io/badge/Dil-VHDL-blue)
![Donanım](https://img.shields.io/badge/Donanım-Basys3-orange)

---

## 📌 Genel Bakış

SunflowerBot, Basys 3 geliştirme kartı üzerinde yer alan Artix-7 FPGA kullanılarak tasarlanmış, otonom ve heliotropik (güneşe yönelen) bir güneş takip sistemidir. Sistem, iki adet Işığa Bağımlı Direnç (LDR) aracılığıyla ortam ışığını algılayarak bir servo motoru en yüksek ışık yoğunluğuna doğru gerçek zamanlı olarak yönlendirir.

Mikrodenetleyici tabanlı çözümlerde görülen sıralı yazılım yürütmenin aksine, bu proje sensör okuma, sinyal işleme ve motor kontrol işlemlerini tamamen donanım seviyesinde ve eşzamanlı olarak gerçekleştirmek üzere FPGA paralelliğinden yararlanmaktadır. Sistem, herhangi bir soft-core işlemciye ihtiyaç duymayan özel bir RTL (Register Transfer Level) mimarisi ile tasarlanmış olup, bu sayede deterministik ve mikrosaniye mertebesinde tepki süreleri elde edilmiştir.

---

## 🛠️ Temel Tasarım Özellikleri

* **⚡ Donanım Hızlandırmalı Kontrol Döngüsü**  
  Sensör gürültüsünü bastırmak ve servo motorun gereksiz salınım yapmasını önlemek amacıyla 300 birimlik ölü banta sahip bir histerezis karşılaştırıcı uygulanmıştır.

* 📈 Sinyal İşleme Hattı (DSP)  
  Ham 12-bit XADC verilerini yumuşatmak için özel olarak tasarlanmış Birinci Dereceden IIR (Sonsuz Dürtü Tepkili) Alçak Geçiren Filtre kullanılmaktadır.

* **🖥️ Bare-Metal LCD Sürücüsü**  
  Harici IP çekirdekleri kullanılmadan, HD44780 LCD protokolü mikrosaniye hassasiyetinde zamanlama gereksinimlerini sağlayan bir Sonlu Durum Makinesi (FSM) ile doğrudan donanımda uygulanmıştır.

* **🎯 Hassas Eyleme Geçirme**  
  Servo motorun mekanik bileşenlerini korumak amacıyla Slew-Rate (değişim hızı) sınırlamalı, 50 Hz PWM üreteci geliştirilmiştir.

* **🔌 XADC Arayüzü**  
  Artix-7 FPGA’nın dahili 12-bit XADC modülü, Dinamik Yeniden Yapılandırma Portu (DRP) üzerinden manuel olarak kontrol edilmiştir.

---

## ⚙️ Sistem Mimarisi

![Sistem_Blok_Diyagramı](https://github.com/user-attachments/assets/2a5c269f-cfff-4a3c-bdd9-182989aae2f3)  
*Şekil 2. SunflowerBot sistem mimarisi*

Sistem, tamamen paralel çalışan bir “Algıla – Karar Ver – Eyleme Geç” yapısı üzerine kurulmuştur.

### 1. Algılama (`xadc_interface.vhd`)
* **Giriş:** Gerilim bölücü yapılandırmasında iki adet LDR sensörü  
* **Örnekleme:** XADC primitive’i kullanılarak 12-bit çözünürlükte analog-dijital dönüşüm  
* **Kontrol:** Tek ADC çekirdeğini iki analog kanal (VAUX6 & VAUX14) arasında paylaştıran 4 durumlu FSM tabanlı sıralayıcı

### 2. İşleme (`sensor_compare.vhd`, `pwm_gen.vhd`)
* **Karşılaştırma:** Sol ve sağ sensörler arasındaki farkın ($\Delta$) hesaplanması  
* **Filtreleme:**  
   $y[n] = 0.97 \cdot y[n-1] + 0.03 \cdot x[n]$
  denklemi ile yüksek frekanslı gürültünün bastırılması  
* **Karar Mekanizması:** Servo motor yalnızca  
   $|\Delta| > \text{Threshold}$
  koşulu sağlandığında hareket ettirilir.

### 3. Eyleme Geçirme (`pwm_gen.vhd`)
* **PWM Çıkışı:** 50 Hz (20 ms periyot)  
* **Zaman Çözünürlüğü:** 1 µs (döngü başına 20.000 adım)  
* **Konum Aralığı:** 0.5 ms ($0^\circ$) – 2.5 ms ($180^\circ$)

### 4. Geri Bildirim (`lcd_controller.vhd`)
* **Görüntüleme:** Sistem durumu (“SOLA DÖN”, “KİLİTLENDİ”) ve sensör değerleri  
* **Dönüştürme:** Gerçek zamanlı İkili → BCD → ASCII dönüşüm mantığı

---

## 💻 Teknik Uygulama Detayları

### 1. Dijital Sinyal İşleme (DSP)

LDR tabanlı analog ölçümlerde karşılaşılan elektriksel gürültüyü harici filtre elemanları kullanmadan bastırmak amacıyla FPGA içinde Birinci Dereceden IIR filtre uygulanmıştır:

$$y[n] = \frac{31 \cdot y[n-1] + x[n]}{32}$$

* **Donanım Optimizasyonu:** Bölme işlemi, DSP dilimi tüketmeden bit kaydırma (`>>5`) ile gerçekleştirilmiştir.  
* **Titreşim Önleme:** Programlanabilir histerezis eşiği, küçük ışık farklarında servo motorun kararsız davranmasını engeller.

### 2. Servo Kontrolü ve Slew-Rate Sınırlama

Ani konum değişimlerinin neden olduğu mekanik stresleri azaltmak için özel bir Soft-Start (Yumuşak Başlangıç) rampa denetleyicisi geliştirilmiştir.

* `current_pos`, `target_pos` değerine doğru her 15 µs'de yalnızca bir adım ilerler.  
* Bu yapı, pürüzsüz ve mekanik açıdan güvenli bir hareket profili sağlar.

### 3. Özel LCD Sürücüsü (HD44780)

![State_Transition_Table](https://github.com/user-attachments/assets/f2113290-5615-4d34-af94-b5d291377a13)  
*Şekil 3. LCD FSM durum geçiş diyagramı*

* **FSM Yapısı:** Mealy tipi durum makinesi  
* **Zamanlama:** 50 µs kurulum süresi, 2 ms komut yürütme gecikmesi  
* **Veri Dönüşümü:** Harici lookup table yerine gerçek zamanlı ASCII üretimi

### 4. XADC Arayüzleme

XADC’nin otomatik sıralayıcısı bypass edilerek, DRP üzerinden tamamen deterministik bir manuel sıralama yapılmıştır.

* **Kanal Adresleri:** `0x16` (VAUX6), `0x1E` (VAUX14)  
* **Kontrol:** `EOC` sinyali ile dönüşüm senkronizasyonu  
* **Çözünürlük:** 0–4095 aralığında tam 12-bit ölçüm hassasiyeti

---

## 🔌 Donanım Pin Bağlantıları (Basys 3)

| Bileşen | Sinyal | FPGA Pini | Açıklama |
|------|------|---------|---------|
| Sistem | `clk` | W5 | 100 MHz Dahili Saat |
| Sensör (Sol) | `vauxp6/vauxn6` | J3/K3 | Sol LDR |
| Sensör (Sağ) | `vauxp14/vauxn14` | L3/M3 | Sağ LDR |
| Servo | `servo_pwm` | A14 | PWM Çıkışı |
| LCD | `lcd_rs` | A16 | Register Select |
| LCD | `lcd_en` | B15 | Enable |
| LCD | `lcd_data[0–7]` | K17–R18 | Veri Yolu |

---

## 🎥 Gösterim

[▶️ Tam Mühendislik Analizini YouTube’da İzleyin](https://youtu.be/HuF9bkv2JE8)

---
