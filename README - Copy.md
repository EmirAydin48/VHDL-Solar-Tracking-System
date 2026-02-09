# SunflowerBot: FPGA Tabanlı Otonom Güneş Takip Sistemi

![demo](https://github.com/user-attachments/assets/1536b20f-7956-42f9-8431-87e7970cd9c4)

*Şekil 1. Projenin Çalışma Gösterimi*

![Durum](https://img.shields.io/badge/Status-Completed-success) ![Teknoloji](https://img.shields.io/badge/Language-VHDL-blue) ![Donanım](https://img.shields.io/badge/Hardware-Basys3-orange) ![Lisans](https://img.shields.io/badge/License-MIT-green)

## 🌻 Genel Bakış

SunflowerBot (Ayçiçeği Robotu), Artix-7 FPGA (Basys 3) üzerinde tasarlanmış otonom, heliotropik (güneşe yönelen) bir takip sistemidir. Doğayı taklit ederek, bir çift Işığa Bağımlı Direnç (LDR) kullanır ve bir servo motoru gerçek zamanlı olarak en parlak ışık kaynağına doğru aktif bir şekilde yönlendirir.

Sıralı yazılım yürütmeye dayalı mikrodenetleyici tabanlı çözümlerin aksine, bu proje sensör veri toplama, sinyal işleme ve motor kontrol işlemlerini donanımda eşzamanlı olarak yürütmek için FPGA paralelliğinden yararlanır. Sistem, soft-core bir işlemciye ihtiyaç duymadan tasarlanmış özel bir RTL (Register Transfer Level) tasarımına sahiptir; bu sayede deterministik (belirlenimci) ve mikrosaniye seviyesinde tepki süreleri sağlanır.

 🛠️ Temel Mühendislik Özellikleri

* ⚡ Donanım Hızlandırmalı Kontrol Döngüsü
    * Sensör gürültüsünü ortadan kaldırmak ve servonun "titreşimini" (hızlı salınım) önlemek için 300 birimlik ölü banta (deadband) sahip bir Histerezis Karşılaştırıcı uygular.
* Sinyal İşleme Hattı (DSP)
    * Eyleme geçmeden önce ham 12-bit sensör verilerini yumuşatmak için özel bir Sonsuz Dürtü Tepkili (IIR) Alçak Geçiren Filtre içerir.
* Bare-Metal (Yalın) LCD Sürücüsü
    * Harici IP çekirdekleri kullanmadan mikrosaniye seviyesindeki zamanlama kısıtlamalarını yöneten, HD44780 protokolünün manuel bir Sonlu Durum Makinesi (FSM) uygulamasıdır.
* Hassas Eyleme Geçirme
    * Servoyu kademeli olarak hızlandırarak mekanik bileşenleri yüksek tork stresinden korumak için Slew-Rate Sınırlamalı (Yükselme Hızı Sınırlama) 50Hz PWM Üreteci.
* XADC Arayüzü
    * Dahili 12-bit Analog-Dijital Dönüştürücüyü sıralamak için Artix-7 Dinamik Yeniden Yapılandırma Portunun (DRP) doğrudan kontrolü.

## ⚙️ Sistem Mimarisi

![Sistem_Blok_Diyagramı](https://github.com/user-attachments/assets/2a5c269f-cfff-4a3c-bdd9-182989aae2f3)
*Şekil 2. Sistemin Blok Diyagramı*

Mimari, tamamen paralelleştirilmiş bir "Algıla-Düşün-Hareket Et" hattıdır:

### 1. Algılama (`xadc_interface.vhd`)
* **Giriş:** Gerilim bölücü oluşturan 2 adet Işığa Bağımlı Direnç (LDR).
* **Mekanizma:** Analog gerilimleri 12-bit çözünürlükte örneklemek için XADC ilkelini (primitive) kullanır.
* **Mantık:** Tek ADC çekirdeğini iki analog kanal (VAUX6 & VAUX14) arasında çoğullamak (multiplex) için 4 durumlu bir sıralayıcı kullanır.

### 2. İşleme (`sensor_compare.vhd` & `pwm_gen.vhd`)
* **Karşılaştırma:** Sol ve Sağ sensörler arasındaki farkı ($\Delta$) hesaplar.
* **Filtreleme:** Bir IIR filtre uygular: $y[n] = 0.97 \cdot y[n-1] + 0.03 \cdot x[n]$. Bu, yüksek frekanslı gürültüyü (gölge titremesi) sönümler.
* **Karar:** Servo motoru yalnızca $|\Delta| > \text{Eşik Değeri}$ ise hareket ettirir.

### 3. Eyleme Geçirme (`pwm_gen.vhd`)
* **Çıkış:** 50Hz PWM Sinyali (20ms Periyot).
* **Çözünürlük:** 1µs hassasiyet (döngü başına 20.000 adım).
* **Aralık:** Sensör farkını 0.5ms ($0^\circ$) ile 2.5ms ($180^\circ$) arasındaki bir darbe genişliğine eşler.

### 4. Geri Bildirim (`lcd_controller.vhd`)
* **Görseller:** Gerçek zamanlı durumu ("SOLA DON", "KILITLENDI") ve ham 12-bit sensör değerlerini görüntüler.
* **Dönüştürme:** İnsan tarafından okunabilir çıktı için ikili-BCD-ASCII dönüştürücü içerir.

### 💻 Teknik Uygulama Detayları

#### 1. Dijital Sinyal İşleme (DSP) Uygulaması
Harici kapasitörler kullanmadan LDR gerilim bölücülerinden gelen elektriksel gürültüyü filtrelemek için grubumuz, doğrudan FPGA yapısı içinde Birinci Dereceden IIR (Sonsuz Dürtü Tepkili) Filtre tasarlamıştır (`pwm_gen.vhd`).

* **Algoritma:** Dijital bir alçak geçiren filtre görevi gören **Üstel Hareketli Ortalama (EMA)** mantığı.
  $$y[n] = \frac{31 \cdot y[n-1] + x[n]}{32}$$
* **Donanım Optimizasyonu:** 32'ye bölme işlemi, standart bölme mantığına kıyasla sıfır DSP dilimi tüketen bit kaydırma (`>> 5`) yoluyla uygulanmıştır.
* **Gürültü Reddi:** Programlanabilir ölü banta (`THRESHOLD = 300`) sahip bir Histerezis Karşılaştırıcı, ışık farkı ihmal edilebilir düzeyde olduğunda servonun salınım yapmasını veya "titremesini" önler.

#### 2. Servo Kontrolü & Slew Rate (Değişim Hızı) Sınırlama
Standart PWM sürücüleri genellikle servoları anında konuma kilitler, bu da yüksek akım sıçramalarına ve dişli aşınmasına neden olur. Grubumuz özel bir "Soft-Start" (Yumuşak Başlangıç) Rampa Denetleyicisi uygulamıştır.

* **Slew Rate Sınırlayıcı:** İkincil bir sayaç (`ramp_timer`) konum güncellemelerini yavaşlatır.
* **Mantık:** `current_pos` (mevcut konum), adım büyüklüğünden bağımsız olarak pürüzsüz, organik bir hız profili oluşturarak `target_pos` (hedef konum) değerine doğru her 1.500 saat döngüsünde ($15\mu s$) yalnızca bir kez artar/azalır.

#### 3. Özel LCD Sürücüsü (HD44780)
Grubumuz, 16x2 LCD ile arayüz oluşturmak ve HD44780 denetleyicisinin katı mikrosaniye seviyesindeki zamanlama gereksinimlerini bir CPU olmadan yönetmek için bare-metal (yalın) bir sürücü geliştirmiştir.

 ![State_Transition_Table](https://github.com/user-attachments/assets/f2113290-5615-4d34-af94-b5d291377a13)
*Şekil 3. LCD Sürücüsünün Durum Geçiş Tablosu*

* **FSM Mimarisi:** Bir Mealy Durum Makinesi başlatma sırasını yönetir (`0x38` İşlev Ayarı $\to$ `0x0C` Ekran Açık $\to$ `0x01` Temizle).
* **Zamanlama Uyumluluğu:** FSM, ekran bozulmasını önlemek için 50µs kurulum süresi (`WAIT_EN` durumu) ve 2ms komut yürütme süresi (`DELAY_STATE`) uygular.
* **Veri Dönüştürme:** Hafıza ağırlıklı bir arama tablosu yerine grubumuz, 12-bit tamsayı sensör değerlerini insan tarafından okunabilir metin olarak işlemek için gerçek zamanlı bir İkili-BCD-ASCII dönüştürme algoritması (`değer + 48`) uygulamıştır.

#### 4. XADC Arayüzleme
Proje, Dinamik Yeniden Yapılandırma Portu (DRP) aracılığıyla deterministik bir Manuel Sıralayıcı uygulamak için XADC'nin otomatik sıralayıcısını atlar (bypass eder).

* **Kanal Çoklama:** FSM, adresleri `0x16` (Aux6) ve `0x1E` (Aux14) arasında açıkça değiştirir ve verileri kilitlemeden önce `EOC` (Dönüşüm Sonu) sinyalini bekler.
* **Çözünürlük:** Artix-7'nin 0V-1V analog giriş aralığına eşlenen tam 12-bit hassasiyeti (0-4095 aralığı) yakalar.

## 🔌 Donanım Pin Bağlantıları (Basys 3)

| Bileşen | Sinyal Adı | FPGA Pini | Açıklama |
| :--- | :--- | :--- | :--- |
| **Sistem** | `clk` | W5 | 100 MHz Dahili Saat |
| **Sensör Sol** | `vauxp6` / `vauxn6` | J3 / K3 | Sol LDR Analog Girişi (JXADC Başlığı) |
| **Sensör Sağ** | `vauxp14` / `vauxn14` | L3 / M3 | Sağ LDR Analog Girişi (JXADC Başlığı) |
| **Servo** | `servo_pwm` | A14 | PWM Sinyal Çıkışı |
| **LCD** | `lcd_rs` | A16 | Register Select (Kayıt Seçme) |
| **LCD** | `lcd_en` | B15 | Enable (Etkinleştirme) Sinyali |
| **LCD** | `lcd_data[0-7]` | K17...R18 | 8-bit Veri Yolu |

## 🎥 Gösterim

[▶️ Tam Mühendislik Analizini YouTube'da İzleyin](https://youtu.be/HuF9bkv2JE8)

---