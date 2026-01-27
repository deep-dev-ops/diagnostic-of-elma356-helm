# Диагностический сценарий для поставки ELMA365 HELM On-premises

# Как пользоваться
Существует несколько вариантов запуска:
1) В случае отсутствия на машине доступа к публичной сети интернет и/или GitHub:
   - Скачать предоставленный файл скрипта сбора информации "diagnosticsELMA365k8s.sh" и разместить на машине, откуда производится управление k8s
   - Добавить прав на запуск сценария:
   ```
   chmod o+x diagnosticsELMA365k8s.sh
   ```
   - Запустить сценарий и ввести названия namespace с ELMA365
   - Передача сформированного архива tar.gz (например "elma365-report-2025-04-21_13-02-23.tar.gz") для изучения

2)  В случае наличия на машине доступа к публичной сети интернет и/или GitHub:
   ```
   sudo -i
   curl -fsSL https://raw.githubusercontent.com/deep-dev-ops/diagnostic-of-elma356-helm/refs/heads/main/diagnostic-bash.sh -o diagnostic-bash.sh && chmod +x diagnostic-bash.sh && ./diagnostic-bash.sh
   ```
