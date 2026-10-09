# Bloom 🌸

Lični dnevnik kilaže, mera i kalorija (Flutter, pravljeno i testirano za iPhone).

- **Merenja jednom nedeljno:** kilaža, grudi, ispod grudi, struk, stomak, kukovi, bokovi, uz belešku. Podsetnik stiže 7 dana posle poslednjeg merenja.
- **Kalorije:** cilj se računa iz godina, visine, kilaže, aktivnosti i tempa (Mifflin-St Jeor), a može i ručno. Svaki dan upisuješ obroke.
- **Koraci:** čitaju se iz aplikacije Zdravlje (Apple Health) i dodaju se dnevnom budžetu. Mogu i ručno.
- **Napredak:** grafikoni za kilažu i svaku meru, kalorije u nedelji, BMI, odnos struk/bokovi i procena do cilja.
- **Podaci** se čuvaju samo na telefonu (shared_preferences). U Profilu postoji izvoz i uvoz JSON rezervne kopije.

## Instalacija na iPhone

Potrebni su ti Mac sa Xcode-om, kabl i Apple ID (besplatan je dovoljan).

1. Poveži iPhone kablom, otključaj ga i na pitanje "Trust This Computer?" izaberi **Trust**.
2. Uključi Developer Mode na iPhone-u: **Settings → Privacy & Security → Developer Mode → On**. Telefon će se restartovati. (Ova opcija se pojavi tek kad je iPhone jednom povezan sa Xcode-om.)
3. Otvori projekat u Xcode-u:
   ```bash
   open ~/Desktop/bloom/ios/Runner.xcworkspace
   ```
4. U Xcode-u otvori **Settings → Accounts → +** i dodaj svoj Apple ID.
5. U levoj koloni klikni na **Runner**, pa target **Runner**, pa tab **Signing & Capabilities**. Kod **Team** izaberi "Tamara Cakarevic (Personal Team)". HealthKit je već uključen.
6. Pokreni instalaciju:
   ```bash
   cd ~/Desktop/bloom
   flutter run --release
   ```
   Koristi `--release`, jer debug verzija na pravom iPhone-u radi samo dok je povezana sa Mac-om.
7. Kod prvog pokretanja iPhone traži da potvrdiš developera: **Settings → General → VPN & Device Management → [tvoj Apple ID] → Trust**.
8. U aplikaciji klikni **Poveži sa Zdravljem** i dozvoli **Koraci**.

**Na svakih 7 dana** (sa besplatnim Apple ID-jem) aplikacija prestaje da se otvara. Poveži telefon i ponovo pokreni `flutter run --release`. **Podaci ostaju.** Sa plaćenim Apple Developer nalogom ($99 godišnje) instalacija važi godinu dana.

## Razvoj

```bash
flutter pub get
flutter test                      # testovi proračuna
open -a Simulator && flutter run  # iPhone simulator
```

> Xcode ovde koristi lokalni build folder `build/DerivedData` (podešeno u `ios/Runner.xcworkspace/xcuserdata`). Kada je disk skoro pun, macOS briše globalni Xcode keš usred build-a.
