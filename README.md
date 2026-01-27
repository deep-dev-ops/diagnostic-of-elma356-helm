# Диагностический сценарий для поставки ELMA365 HELM On-premises

# Требования
1) Наличие curl, jq, kubectl на машине
2) Наличие доступа через kubeconfig ко всему кластеру (собирается не только информация с указанного ns)
3) Наличие у пользователя root привилегий

# Как пользоваться скриптом:
Существует несколько вариантов запуска:

### I) В случае отсутствия на машине доступа к публичной сети интернет и/или GitHub:
   1) Скачать предоставленный файл скрипта сбора информации "diagnosticsELMA365k8s.sh" либо напрямую отсюда либо на машине где есть доступ к сети интернет и имеется curl
   ```
   curl -fsSL https://raw.githubusercontent.com/deep-dev-ops/diagnostic-of-elma356-helm/refs/heads/main/diagnostic-bash.sh
   ```
   
   2) Разместить на машине с kubectl, откуда производится управление k8s c помощью ftp либо иными способами
   3) Добавить прав на запуск сценария (требуется root привилегии):
   ```
   sduo chmod o+x diagnosticsELMA365k8s.sh
   ```
   3) Запустить сценарий и ввести названия namespace с ELMA365 (требуется root привилегии):
   ```
   sudo ./diagnostic-bash.sh
   ```
   4) Передача сформированного архива tar.gz (например "elma365-report-2025-04-21_13-02-23.tar.gz") для изучения специалистам


### II)  В случае наличия на машине доступа к публичной сети интернет и/или GitHub:
   1) Перейти в интеративную shell-сессию от root
   ```
   sudo -i
   ```
   2) Скопировать ссылку, вставить в терминал и отправить, после чего ввести ns с ELMA365
   ```
   curl -fsSL https://raw.githubusercontent.com/deep-dev-ops/diagnostic-of-elma356-helm/refs/heads/main/diagnostic-bash.sh -o diagnostic-bash.sh && chmod +x diagnostic-bash.sh && ./diagnostic-bash.sh
   ```
   3) Передача сформированного архива tar.gz (например "elma365-report-2025-04-21_13-02-23.tar.gz") для изучения специалистам

### III) Скопировать код скрипта
   1) Скопировать код на странице просмотра https://raw.githubusercontent.com/deep-dev-ops/diagnostic-of-elma356-helm/refs/heads/main/diagnostic-bash.sh
   2) В терминале на удаленной машине с kubectl и jq создать файл и вставить в него код
   3) Предоставить права и запустить код
   ```
   sudo chmod +x diagnostic-bash.sh && sudo ./diagnostic-bash.sh
   ```


> Обратите, пожалуйста, внимание на то что процесс предоставления прав, а также запуск осуществляется с root. В зависимости от настройки kubectl и окружения запуск с "sudo ./diagnostic-bash.sh" может неверно работать и скрипт может выдать ошибку "Required tool 'kubectl' is not installed. Please install it and try again.". В таких случаях рекомендует правильно настроить kubectl для окружений пользователей машины либо предварительно переходить в интеративную shell-сессию от root (sudo -i)
   
