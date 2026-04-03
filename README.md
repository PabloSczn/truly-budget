# TrulyBudget

TrulyBudget is a local-first monthly budgeting app built for people who want a clearer, calmer way to manage their money month by month. Instead of burying your budget in spreadsheets or overcomplicating everything with banking integrations, it helps you do the essentials well: create a month, add your income, allocate it by amount or percentage, track spending by category, and instantly see what is left, what is over budget, and where debt is building up.

It is designed to stay practical and easy to keep using. You can carry debt into the next month when needed, review your whole year at a glance, switch between GBP, EUR, USD, JPY, and INR, and export month or year reports as PDF, JPG, or XLSX plus a full ZIP backup. All data is stored locally on your device, so your budget stays simple, fast, and under your control.

Start using it now!

## Setup

```bash
flutter pub get
flutter run

# optional but recommended for local development
pipx install pre-commit
pre-commit install
pre-commit run --all-files
```

Use Flutter stable with a configured device, emulator, simulator, or browser. The pre-commit hook runs `dart tool/lint_and_fix.dart`, which formats, applies fixable lints, and analyzes the project before commit.

## License

This repository is source-available under PolyForm Strict 1.0.0. That prevents commercial use, redistribution, and modified or derivative re-releases of this codebase. It protects the code and assets in this repo, not the budgeting idea by itself.

This repository is public for transparency and reference, but external contributions are not being accepted. See [CONTRIBUTING.md](CONTRIBUTING.md).

You can still view and fork this repository on GitHub under GitHub's Terms of Service.
