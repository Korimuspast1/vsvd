# Сборка VSVD на базе Telegram Android

## База

VSVD опирается на точный commit `dc780e81ed1261c369c27870e8e0999a1eb0b600` официального репозитория Telegram Android, подключённый как `upstream/telegram-android`. Все изменения VSVD лежат отдельно в `patches/telegram-android/`, поэтому их легко просмотреть и перенести на следующую версию upstream.

## Требования

Текущий upstream требует:

- Android Studio 2025.1.4;
- Android SDK Platform 36 и Build Tools 36.0.0;
- Android NDK 27.2.12479018;
- JDK, Git, CMake и достаточно места для нативных зависимостей;
- доступ к репозиториям Google/Maven/Gradle для первой сборки.

## Один раз на компьютере разработчика

```bash
git clone --recurse-submodules <URL-репозитория-VSVD>
cd vsvd
git submodule update --init --recursive
cp telegram.properties.example telegram.properties
chmod 600 telegram.properties
```

Создай собственное API-приложение в `my.telegram.org` и заполни только локальный файл:

```properties
TELEGRAM_API_ID=123456
TELEGRAM_API_HASH=your_hash
```

`telegram.properties` игнорируется Git. Не вставляй его значения в `BuildVars.java`, `gradle.properties`, patch-файлы, README, логи CI или скриншоты.

## Наложение VSVD-функций

```bash
./scripts/apply-vsvd-patches.sh
```

Скрипт проверяет точный revision upstream и откажется применяться к обновлённому или локально изменённому дереву. Это предотвращает случайное наложение патчей на неподходящую версию Telegram.

## Debug-сборка

```bash
cd upstream/telegram-android
./gradlew :TMessagesProj_App:assembleAfatDebug
```

APK создаётся в каталоге модуля `TMessagesProj_App/build/outputs/`. Точная вложенная папка зависит от версии Android Gradle Plugin и variant.

## Release APK

Release-задача теперь намеренно остановится, если нет отдельного ключа VSVD — sample keystore из upstream не используется для релиза.

```bash
cd .. # вернуться в корень VSVD
mkdir -p signing
# Создаёт PKCS12 signing key; введённый пароль запиши только в локальный файл.
openssl req -x509 -newkey rsa:4096 -keyout signing/vsvd-release.key.pem \
  -out signing/vsvd-release.cert.pem -days 3650
openssl pkcs12 -export -out signing/vsvd-release.p12 -name vsvd \
  -inkey signing/vsvd-release.key.pem -in signing/vsvd-release.cert.pem
rm signing/vsvd-release.key.pem signing/vsvd-release.cert.pem
cp vsvd-signing.properties.example vsvd-signing.properties
# Заполни пароль хранилища/ключа в локальном vsvd-signing.properties.

# Или одной командой из корня VSVD:
./scripts/build-release-apk.sh

# Эквивалентная Gradle-задача:
cd upstream/telegram-android
./gradlew :TMessagesProj_App:assembleAfatRelease
```

Полученный APK нужно подписать только собственным ключом VSVD и проверить на устройстве до публикации. Нельзя публиковать APK с демонстрационным keystore и `google-services.json`, которые есть в upstream как заглушки.

Также добавлен workflow `.github/workflows/build-release.yml` для GitHub Actions. Он ждёт три repository secrets: `VSVD_TELEGRAM_PROPERTIES_B64`, `VSVD_SIGNING_PROPERTIES_B64` и `VSVD_RELEASE_KEYSTORE_B64`. Они содержат base64 локальных файлов и никогда не должны коммититься.

## Проверки перед распространением

1. Package ID — `dev.vsvd.client`, отображаемое имя — `VSVD`, иконка — собственная.
2. `BuildVars.APP_ID` и `APP_HASH` берутся из локального BuildConfig, а не из ключей Telegram.
3. Нет утечки API hash или номера/кода входа в Logcat, crash-reporting или HTTP-логи.
4. Control Plane не включён как прокси Telegram-трафика.
5. Исходный код VSVD, патчи и GPL-информация доступны тем, кому распространяется APK.
