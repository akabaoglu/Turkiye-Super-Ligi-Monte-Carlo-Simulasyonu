# Simülasyona Dair Teknik Açıklamalar
1. Raporda belirtildiği üzere simülasyonda canlandırılan maçların sonuçlarına dair olasılıklar *Bet365* bahis şirketinin oranlarına göre tayin edilmiştir. Bu oranlara [www.football-data.co.uk](https://www.football-data.co.uk/data.php) websitesinden ulaşılabilir. Analizin kapsamında yer alan 2014-24 yılları arasında oynanan on sezonun verisi aynı zamanda mevcut repository'daki `Data` klasöründe mevcuttur.

2. Piyasada faaliyet gösteren diğer şirketler gibi Bet365 sitesi de bahis oranlarını *fractional odds* [^1] formatında vermektedir. Fractional odds olasılıksal değerlerden farklı olarak $[1, \infty)$ aralığında herhangi bir değeri alabilir. Bu değerler $f(x) = \frac{1}{x}$ fonksiyonu ile $[0, 1]$ arasında tanımlı olasılık değelerine dönüştürülmüştür.
3. Bahis şirketleri açtıkları her bir oyunu matematiksel olarak kârlı kılabilmek için *overround* adı verilen bir pratiğe başvurarak, oyunların potansiyel sonuç olasılıklarını toplamda 1'in üzeri değere denk gelecek şekilde belirlerler. Bet365 sitesinin Türkiye Süper Ligi için 2014-2024 yılları arasında ortalama overround oranı yaklaşık %6.9'dur. Simülasyonda Bet365 sitesinin bahis oranları overround oranı kaldırılarak, olasılıklar toplamda 1'e karşılık gelecek şekilde yeniden ölçeklenmiştir.
4. Bet365 şirketi 10 sezonda oynanmış toplam 14 maç için bahis açmamıştır. Bu maçların sezonlara göre dağılımı aşağıdaki gibidir:

<div align="center">

|  Sezon  | Maç Sayısı|
|---------|:-:|
| 2015-16 | 1 |
| 2017-18 | 3 |
| 2020-21 | 5 |
| 2022-23 | 4 |
| 2023-24 | 1 |

</div>

<ul>
Bunlara ek olarak, 2022-23 sezonunun ikinci yarısında Gaziantepspor ve Hatayspor'un oynamasının planlandığı 29 maç 6 Şubat depremi sebebiyle oynanamamıştır. Simülasyonda bu maçlar oynanmış kabul edilmiş, toplam 43 maçın sonuç olasılıklarının belirlenmesinde takımların ligin diğer yarılarında karşılaştıkları maçların bahis oranları referans alınmıştır. Bu maçların tam listesine <a href="https://github.com/akabaoglu/Turkiye-Super-Ligi-Monte-Carlo-Simulasyonu/blob/main/Misc/MissingGames.md">buradan</a> ulaşılabilir.
</ul>

5. Kullanılan bahis verileri 2014-2024 yılları arasında Türkiye Süper Liginde oynanan maçların sadece galibiyet, beraberlik ve mağlubiyet olasılıklarını barındırmakta; atılan gol, yenilen gol, sarı kart sayısı vs. değerlere yönelik herhangi bir olasılık sunmaktadır. Bu sebeple, simülasyon sadece maçın sonucuna (ev sahibi galibiyeti, konuk takım galibiyeti veya beraberlik) odaklanmış, maçın skoru ve tarafların gördüğü sarı/kırmızı kart sayıları simüle edilmemiştir.
 
6. Bu şartlar altında matematiksel olarak her bir maçın sonucu kendine özgü *Multinomial* [^2] dağılımında rastgelen seçilen bir gözlemle belirlenmiştir. Maçlara özgü Multinomial dağılımlarda $k$ parametresi her maç için $[1, 0, 2]$ vektörüdür. Bu değerler sırasıyla ev sahibi galibiyeti, beraberlik ve konuk takım galibiyeti sonuçlarına karşılık gelir. Diğer yandan $p$ parameteresi her maç için değişiklik göstermektedir. Örneğin, 2014-15 sezonu ilk haftasında oynanan Trabzonspor-Antalyaspor maçı için $p = [0.501, 0.255, 0.244]$ iken, aynı hafta oynanan Kasımpaşa-Ankaragücü için $p = [0.418, 0.263, 0.319]$. En kaba şekilde ifade etmek gerekirse, $k$ parametresi Multinomial dağılımın potansiyel sonuçlarını ifade ederken, $p$ parametresi bu sonuçların sırasıyla olasılıklarını içerir. 
7. Eldeki bahis verilerine göre ikili averaj, toplam gol, toplam görülen kart gibi parametreleri değerlendirmek mümkün olmadığı için, puan bazından birden çok takımın lider tamamladığı sezonlarda şampiyonluk simülasyonda kura ile belirlenmiştir.
8. Ligden düşme ve çıkma durumları simülasyon kapsamında ihmal edilmiştir. Bu tercih iki sebeple yapılmıştır: (1) Lig düşme/çıkma dinamiğinin tam anlamıyla simülasyona yansıtılabilmesi için tüm alt liglerde oynanan maçların da simüle edilmesi gerekmektedir. Bu maçlara dair maalesef elde bir veri bulunmamaktadır. (2) Simülasyonun herhangi bir turunda önde gelen takımların şans eseri ligden düşmesi durumunda, ertesi sezon ligin içinde bulunduğu şartlar radikal biçimde değişecek, simüle etmesi beklenen sezonun sportif dinamiklerini artık yansıtmayacaktır. Bu, simülasyonun ana maksadının son Süper Lig'de oynanan son on sezonu kendi iç dinamikleri dahilinde yeniden canlandırmak olduğu düşünülürse, gerçekleşmesini arzu ettiğimiz bir durum değildir. 
11. Simülasyonda her bir maçın sonucu olasılıklara dayalı olarak rastgele belirlendiği için, sonuçları tekrar edilebilir kılmak adına Julia yazılım dili ekosisteminde yer alan [Random.jl](https://docs.julialang.org/en/v1/stdlib/Random/) paketinin `seed!` fonksiyonu ile rastgele sayı üretim *seed* değeri 12345'e sabitlenmiştir. Bu değer sabit tutulduğu sürece simülasyon kapsamında oynatılan $3,358\times 1,000,000$ maç aynı sonucu verecek, lig liderlerinin aynı puanla sezonu tamamladığı durumlarda çekilen kuradan aynı takım şampiyon çıkacaktır.
12. Simülasyon sonuçlarını bizatihi incelemek isteyenler repository'de yer alan `Script.jl` dosyasını Julia dilinde çalıştırarak rapordaki bulgulara temel teşkil eden sonuçların tıpkısını yerel bilgisayarlarında oluşturabililirler. Aynı dosyada *RESULTS & ANALYSIS* başlığı altında yer alan kodlarla rapordaki istatistiki analizler tekrarlanabilir, ilişkili görselleştirmeler de yerel bilgisayarda oluşturulabilir. Simülasyonun $1,000,000$ turu Apple M1 Pro işlemciye sahip makinada paralel işlem kullanılmaksızın yaklaşık 1 saat 40 dk'da tamamlanmıştır.


[^1]: [Odds](https://en.wikipedia.org/wiki/Odds) 
[^2]: [Multinomial Distribution](https://en.wikipedia.org/wiki/Multinomial_distribution)
