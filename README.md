🚀 Conectar.ps1 — Suporte Remoto Rápido

Este repositório contém um script em PowerShell projetado para iniciar uma sessão de suporte remoto de forma rápida, segura e sem necessidade de instalação prévia, utilizando a versão portátil oficial do RustDesk.

💻 Como Executar (Passo a Passo)

Para iniciar o atendimento remoto no computador que receberá o suporte, siga as instruções abaixo:

Abra o PowerShell como Administrador:

Clique no menu Iniciar (ou pressione as teclas Win + X).

Selecione Terminal (Administrador) ou Windows PowerShell (Administrador).

Clique em Sim na janela de confirmação do Windows.

Execute o comando de conexão:
Copie o comando abaixo, cole na janela azul ou preta do PowerShell e pressione Enter:

irm https://raw.githubusercontent.com/guiixiis/conectar.ps1/main/conectar.ps1 | iex


Compartilhe os dados de acesso:

Aguarde alguns segundos até que a janela do RustDesk abra automaticamente na tela.

No painel esquerdo (Seu Computador), informe ao técnico o seu ID e a Senha de uso único.

🛡️ Sobre Permissões de Administrador (UAC)

Ao abrir o programa, você verá um aviso na cor rosa no canto inferior esquerdo informando sobre o UAC (Controle de Conta de Usuário):

Modo Portátil (Padrão): O programa não altera o sistema e não deixa rastros. Porém, sempre que o técnico precisar abrir uma ferramenta administrativa, você precisará clicar em "Sim" na tela de confirmação do Windows.

Modo Instalado (Opcional): Caso não possa ficar em frente ao computador durante a manutenção, clique no botão Instalar dentro da caixa rosa. Isso permite que o técnico gerencie as confirmações do Windows remotamente (o programa poderá ser desinstalado normalmente pelo Painel de Controle após o serviço).

⚙️ O que o script faz por baixo dos panos?

O código hospedado em conectar.ps1 executa as seguintes etapas de forma automatizada:

Compatibilidade de Segurança (TLS 1.2): Força o protocolo de segurança moderno no PowerShell ([Net.ServicePointManager]::SecurityProtocol), evitando erros de conexão em sistemas Windows 10 mais antigos.

Aceleração de Download: Desativa a barra de progresso visual do PowerShell ($ProgressPreference = 'SilentlyContinue'), tornando o download até 3x mais rápido.

Busca da Versão Mais Recente: Consulta a API oficial do GitHub do RustDesk para localizar automaticamente o link de download da última versão estável para Windows 64-bit (x86_64.exe).

Prevenção de Conflitos: Salva o executável na pasta temporária do Windows (%TEMP%) com um identificador numérico aleatório (RustDesk_XXXX.exe), evitando erros caso o comando seja executado mais de uma vez na mesma máquina.

Execução Imediata: Inicia o cliente portátil assim que a transferência é concluída.

⚠️ Requisitos e Limitações de Rede

Sistema Operacional: Windows 10 ou Windows 11 (64-bit).

Acesso à Internet: Necessário para consultar a API do GitHub e baixar o cliente oficial.

Redes Corporativas / Institucionais: O RustDesk utiliza a porta 21116 (TCP/UDP) para estabelecer conexão com seus servidores públicos. Em redes empresariais com firewalls restritivos, essa porta pode estar bloqueada, sendo necessário utilizar uma rede doméstica ou roteamento via dados móveis (4G/5G).
