# SekretovOS на GitHub

Репозиторий: https://github.com/smethankin/SekretovOS

## 1. Залить файлы (репозиторий сейчас пустой)

### Вариант A — только установщик (одна команда в OC)

На GitHub: **Add file → Upload files** → залей:

- `sekretov-install.lua` (из корня проекта)

Commit → **main**.

### Вариант B — весь проект (git)

```powershell
cd "C:\Users\Job\Desktop\SekretovOS"
git init
git add .
git commit -m "Initial SekretovOS"
git branch -M main
git remote add origin https://github.com/smethankin/SekretovOS.git
git push -u origin main
```

(нужен вход в GitHub: браузер или `gh auth login`)

---

## 2. Raw URL (после загрузки)

Установщик:

```
https://raw.githubusercontent.com/smethankin/SekretovOS/main/sekretov-install.lua
```

Запуск OS без установщика (если залита вся папка):

```
https://raw.githubusercontent.com/smethankin/SekretovOS/main/main.lua
```

---

## 3. OpenComputers — установка

**wget:**

```lua
wget -O sekretov https://raw.githubusercontent.com/smethankin/SekretovOS/main/sekretov-install.lua
sekretov
```

**internet (если нет wget):**

```lua
local internet = require("internet")
local url = "https://raw.githubusercontent.com/smethankin/SekretovOS/main/sekretov-install.lua"
local f = io.open("sekretov", "w")
for c in internet.request(url, 15, {["User-Agent"]="Mozilla/5.0"}) do f:write(c) end
f:close()
loadfile("sekretov")()
```

Потом:

```lua
/SekretovOS/main
```

---

## 4. Проверка с ПК

Открой в браузере raw-ссылку — должен открыться **текст Lua**, не HTML 404.
