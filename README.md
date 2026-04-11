# Bhaal Armory

Мод для Baldur's Gate 3: три артефакта бога убийств, выдаются персонажу-плуту при создании.

## Что в моде

### Печатка Избранного Баала (кольцо)
- Защита от критических ударов (криты по вам = обычные удары)
- Иммунитет к обворожению и параличу
- **Проекции Баала** — раз за бой призывает три красные иллюзорные копии в стиле Саревока. Каждая поглощает одну атаку.

### Кровожадность (кинжал)
- Визуал кинжала Долора
- -2 к порогу критического удара (крит на 18+)
- +3 зачарование, +1d6 некротического урона
- Игнорирует все сопротивления и иммунитеты к урону
- **+6 к урону с 4 уровня**
- **+4 к КЗ**, если вторая рука свободна (без щита/второго оружия)
- Каждый удар накладывает Молчание и Кровотечение на 2 хода
- Иммунитет к обезоруживанию
- **Подрыв трупа** — раз за бой: взрывает труп, 12d6 огня + 6d6 некроса в радиусе 4м, бьёт всех в зоне (врагов, союзников, кастера), Dex спас DC 18

### Амулет Баала
- Визуал амулета Баала из акта 3
- +4 к Выносливости
- **Преимущество на все броски атаки**
- Защита от проклятия теней (акт 2)
- **Аура Убийства** (раз за короткий отдых, с 10 уровня) — враги в радиусе 3м получают уязвимость к колющему урону

## Установка

1. Скопировать `BhaalGifts.pak` в `%LocalAppData%\Larian Studios\Baldur's Gate 3\Mods\`
2. Активировать мод в менеджере модов (BG3 Mod Manager)
3. **Начать новую игру** — предметы выдаются при создании персонажа

## Совместимость

- Работает без Script Extender
- Предметы выдаются **всем классам** при создании (ограничить только Dark Urge без SE нельзя)
- Зависимость: GustavX (базовая)

## Сборка

```bash
# Конвертация локализации
Divine.exe -g bg3 -a convert-loca -s Localization/Russian/BhaalGifts.loca.xml -d build/Localization/Russian/BhaalGifts.loca
Divine.exe -g bg3 -a convert-loca -s Localization/English/BhaalGifts.loca.xml -d build/Localization/English/BhaalGifts.loca

# Конвертация root templates
Divine.exe -g bg3 -a convert-resource -s Public/BhaalGifts/RootTemplates/BhaalGifts.lsx -d build/Public/BhaalGifts/RootTemplates/_merged.lsf -i lsx -o lsf

# Сборка пака
Divine.exe -g bg3 -a create-package -s build -d BhaalGifts.pak
```

## Структура

```
Mods/BhaalGifts/meta.lsx                            — манифест мода
Public/BhaalGifts/Stats/Generated/
  ├── Equipment.txt                                 — стартовая экипировка плута
  └── Data/
      ├── Armor.txt                                 — кольцо и амулет
      ├── Weapon.txt                                — кинжал
      ├── Passive.txt                               — все пассивки
      ├── Spell_Shout.txt                           — проекции, аура
      ├── Spell_Target.txt                          — подрыв трупа
      ├── Spell_Projectile.txt                      — вспомогательный снаряд взрыва
      └── Status_BOOST.txt                          — статусы проекций, аура, уязвимость
Public/BhaalGifts/RootTemplates/BhaalGifts.lsx      — шаблоны предметов
Localization/Russian/BhaalGifts.loca.xml            — русская локализация
Localization/English/BhaalGifts.loca.xml            — английская локализация
```
