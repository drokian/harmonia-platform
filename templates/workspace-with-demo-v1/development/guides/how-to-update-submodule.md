# Submodule Nasil Guncellenir

`demo/` bir Git submodule'udur; workspace onu belirli bir commit'te "pinler". Demo'da degisiklik oldugunda workspace'in bu pin'i ilerletmesi gerekir.

## Demo Repo'da Degisiklik Yapildiginda

```bash
# 1. Demo submodule'e gir
cd demo

# 2. Demo repo'da degisiklik yap ve push'la
git add -A
git commit -m "feat: yeni ozellik eklendi"
git push origin main

# 3. Workspace'e don
cd ..

# 4. Submodule pin'ini guncelle
git add demo
git commit -m "chore(demo): submodule guncellendi"
git push
```

## Uzak Demo Repo'da (GitHub) Degisiklik Yapildiginda

```bash
# Workspace'teyken submodule'u uzak repo'dan guncelle
git submodule update --remote demo
git add demo
git commit -m "chore(demo): submodule uzaktan guncellendi"
git push
```

## Submodule'u Ilk Kez Klonlama

Workspace'i `git clone` ile aldiktan sonra submodule bos gelir:

```bash
git submodule update --init
# Veya klonlama sirasinda:
git clone --recurse-submodules <workspace-url>
```

## Submodule Durumunu Kontrol Etme

```bash
git submodule status
# Cikti ornegi:
# abc123 demo (v1.2.0)   <- sabitlenmis commit
# +def456 demo (heads/main) <- uzakta yeni commit var
```

`+` oneki: uzak demo ile workspace'in pinledigi commit farkli demektir. Guncelleme gerekebilir.

## Sik Karsilasilan Sorunlar

**`demo/` bos:** `git submodule update --init` calistirin.

**Detached HEAD demo icinde:** Normal durum. Demo'da degisiklik yapacaksaniz once `git checkout main` calistirin.

**Merge conflict `.gitmodules`'de:** Genellikle URL degisikligi. Konflikti elle cozun; hedef URL dogru olmali.
