# Contributing to Recall

Thank you for your interest in contributing to Recall! We welcome bug reports, feature proposals, and pull requests from the open-source community.

---

## 🌟 Code of Conduct

All contributors are expected to uphold our [Code of Conduct](CODE_OF_CONDUCT.md). Please report any unacceptable behavior to project maintainers.

---

## 🛠️ Development Setup

### 1. Fork & Clone
```bash
git clone https://github.com/<your-username>/recall.git
cd recall
git checkout -b feature/your-feature-name
```

### 2. Dependencies & Environment
Install Flutter packages:
```bash
flutter pub get
```

Set up your Gemini API key (optional for UI testing, required for extraction/AI summarization):
- Get a free key from [Google AI Studio](https://aistudio.google.com/app/apikey).
- Run with `--dart-define=GEMINI_API_KEY=your_key` or enter it directly in the in-app **Settings** screen.

---

## 📋 Development Workflow

### Code Generation
If you make changes to database tables in `lib/core/database/` or Riverpod annotations (`@riverpod`), run the code generator:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Static Analysis
Ensure there are 0 analyzer warnings or errors:
```bash
dart analyze
```

### Running Tests
Make sure all existing and new unit/widget tests pass:
```bash
flutter test
```

---

## 📐 Coding Standards & Guidelines

1. **Architecture Layering**:
   - `lib/core/`: Global services, theme, routing, database, AI client, extractors.
   - `lib/data/`: Data models and repository interfaces.
   - `lib/features/`: Feature-scoped screens, widgets, and Riverpod providers.
2. **State Management**:
   - Use Riverpod code generation (`@riverpod`) instead of legacy `StateNotifier` / `ChangeNotifier`.
3. **UI & Design**:
   - Use `material_3_expressive` widgets (`M3EButton`, `M3ECard`, `M3EChip`, `M3EAppBar`, `M3EBottomSheet`, `M3EToolbar`) wrapped in `M3EMaterialApp`.
4. **Secrets & Safety**:
   - **NEVER** commit hardcoded API keys, passwords, or personal credentials.
   - Ensure all secrets are passed via `--dart-define` or stored in `FlutterSecureStorage`.
5. **Documentation**:
   - Provide doc comments (`///`) on all new public classes, methods, and functions.

---

## 🚀 Submitting a Pull Request

1. **Keep PRs focused**: Each PR should address a single bug or feature.
2. **Include tests**: Add unit or widget tests verifying your changes.
3. **Commit cleanly**: Use clear, conventional commit messages (`feat: ...`, `fix: ...`, `docs: ...`, `test: ...`).
4. **Open a PR**: Fill out the pull request template and link any relevant issues.
