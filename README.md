# Projetando 2027

Landing page Flutter Web para a campanha da Igreja Remanescentes.

## Funcionalidades

Editor de avatar 1080×1080 e banner 1920×1080, upload de foto, arrastar, zoom e exportar PNG. Processamento local, sem backend.

## Rodar localmente

```bash
flutter create --platforms=web --project-name projetando_2027 .
flutter pub get
flutter run -d chrome
```

## Publicação

GitHub Settings > Pages > Build and deployment > GitHub Actions. O workflow faz build com `flutter build web --release --base-href /projetando-2027/` e deploy na main.

Endereço esperado: https://tdk17.github.io/projetando-2027/

## Molduras oficiais

Adicionar `assets/frames/avatar.png` e `assets/frames/banner.png` com transparência. Capturas de tela não substituem as molduras. Enquanto não existirem, o editor usa arte provisória.
