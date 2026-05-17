# Установка SekretovOS без Pastebin

Если Pastebin в лимите или paste «на проверке» — используй один из способов ниже.

---

## Способ 1: Флешка / диск (рекомендуется)

### На ПК
1. Вставь в Minecraft дискету или жёсткий диск (OpenComputers).
2. Положи на неё файл:
   `sekretov-install.lua`  
   из папки `SekretovOS` (или всю папку `SekretovOS`).

### В игре (терминал OC)
```lua
ls /mnt
```
Найди точку монтирования, например `/mnt/a1b2/`.

**Вариант A — один установщик:**
```lua
cp /mnt/a1b2/sekretov-install.lua /sekretov
sekretov
```

**Вариант B — вся папка:**
```lua
cp -r /mnt/a1b2/SekretovOS /SekretovOS
/SekretovOS/main
```

---

## Способ 2: GitHub (когда есть аккаунт)

1. Создай репозиторий (можно приватный).
2. Залей `sekretov-install.lua` в корень.
3. Raw-ссылка вида:  
   `https://raw.githubusercontent.com/USER/REPO/main/sekretov-install.lua`

В OpenComputers (нужен Internet Card):

```lua
wget -O sekretov https://raw.githubusercontent.com/USER/REPO/main/sekretov-install.lua
sekretov
```

Если `wget` нет:

```lua
local internet = require("internet")
local f = io.open("sekretov","w")
for c in internet.request("URL_СЮДА",8,{["User-Agent"]="Mozilla/5.0"}) do f:write(c) end
f:close()
loadfile("sekretov")()
```

GitHub raw обычно **не даёт 403**, в отличие от Pastebin.

---

## Способ 3: Другой компьютер в сети OC

На «главном» ПК с папкой `SekretovOS` в `/SekretovOS`:

```lua
/SekretovOS/main
```

Скопируй папку на второй компьютер через:
- общий диск в сети модов,
- `cp` с `/mnt/...`,
- или FTP/HTTP если настроен на сервере.

---

## Способ 4: Минимальный ручной старт (без установщика)

Скопируй **всю папку** `SekretovOS` на диск OC в `/SekretovOS` (структура как в проекте).

```lua
/SekretovOS/main
```

Установщик `sekretov-install.lua` **не обязателен**, если файлы уже на месте.

---

## После установки

```lua
/SekretovOS/main
```

| Клавиша | Действие |
|---------|----------|
| `L` | Launcher |
| Клик по часам | Launcher |
| Ctrl+C | Выход |

---

## Когда Pastebin снова доступен

1. Paste должен быть **Public** и прошёл модерацию.
2. Лучше один файл `sekretov-install.lua` (base64), не 17 отдельных paste.
3. В OC использовать `oc-download.lua` или `/dl/` + User-Agent, не голый `pastebin get`.
