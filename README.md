# Bloom 🌸

Lični dnevnik kilaže, mera i kalorija (Flutter web app za iPhone početni ekran).

- **Merenja jednom nedeljno:** kilaža, grudi, ispod grudi, struk, stomak, kukovi, bokovi, uz belešku. Podsetnik stiže 7 dana posle poslednjeg merenja.
- **Kalorije:** cilj se računa iz godina, visine, kilaže, aktivnosti i tempa (Mifflin-St Jeor), a može i ručno. Svaki dan upisuješ obroke.
- **Koraci:** čitaju se iz aplikacije Zdravlje (Apple Health) i dodaju se dnevnom budžetu. Mogu i ručno.
- **Napredak:** grafikoni za kilažu i svaku meru, kalorije u nedelji, BMI, odnos struk/bokovi i procena do cilja.
- **Podaci** se čuvaju samo na telefonu (shared_preferences). U Profilu postoji izvoz i uvoz JSON rezervne kopije.

## Instalacija na iPhone (web app, bez Mac-a)

1. Napravi build: `flutter build web --release --web-renderer html`. Gotov sajt je u `build/web`.
2. Postavi ga na hosting, npr. na [app.netlify.com/drop](https://app.netlify.com/drop): prevuci folder `build/web` i dobiješ link.
3. Na iPhone-u otvori link u **Safariju**, klikni **Share (kvadrat sa strelicom) → Add to Home Screen → Add**.
4. Od tada otvaraj Bloom **samo preko ikonice**. Ona ima svoje podatke, odvojene od Safarija.

Na webu se koraci upisuju ručno (web ne može da čita aplikaciju Zdravlje), a nema ni obaveštenja. Na početnom ekranu aplikacije i dalje stoji podsetnik kad je vreme za merenje. Podaci ostaju na telefonu, a rezervnu kopiju praviš preko Profil → Sačuvaj → Save to Files.

**Nova verzija:** ponovi korak 1 i prevuci novi `build/web` na Netlify (Deploys → drag & drop).

## Prava iOS aplikacija (opciono)

Kod podržava i pravu iOS aplikaciju sa automatskim koracima iz Zdravlja: `flutter run --release` sa povezanim iPhone-om, a u Xcode-u **Signing & Capabilities → Team** izaberi svoj Apple ID. Sa besplatnim Apple ID-jem instalacija važi 7 dana.

## Razvoj

```bash
flutter pub get
flutter test                      # testovi proračuna
open -a Simulator && flutter run  # iPhone simulator
```

> Xcode ovde koristi lokalni build folder `build/DerivedData` (podešeno u `ios/Runner.xcworkspace/xcuserdata`). Kada je disk skoro pun, macOS briše globalni Xcode keš usred build-a.
