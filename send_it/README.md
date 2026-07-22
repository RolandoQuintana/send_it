# send_it

A group messaging app for iOS — send messages to contact groups via your preferred apps.

## Install

```bash
fvm install          # if first time (see .fvmrc)
fvm flutter pub get
```

## Start

```bash
fvm flutter run
```

## Test

```bash
fvm flutter test
```

## Lint / Analyze

```bash
fvm flutter analyze
```

## Build (iOS)

```bash
fvm flutter build ios --no-codesign
```

---

## TAC OS

This project uses [TAC OS](tac-os/README.md) for agentic development (git submodule).

**Setup (already done):**
```bash
git submodule update --init --recursive
./tac-os/scripts/bootstrap.sh --brownfield
```

**First workflow (fresh agent each step):**
1. `/prime`
2. `/chore "your first chore"` or `/research "new feature idea"`
3. `/implement specs/<plan>.md`

See `tac-os/BOOTSTRAP.md` for full guide.

**Update TAC OS submodule:**
```bash
cd tac-os && git pull origin main && cd ..
git add tac-os && git commit -m "chore: bump tac-os submodule"
```
