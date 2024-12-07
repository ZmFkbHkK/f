import subprocess

# Fungsi untuk menjalankan perintah di terminal
def install_package(package_name):
    try:
        subprocess.run(['sudo', 'apt', 'install', '-y', package_name], check=True)
        print(f"Berhasil menginstal {package_name}")
    except subprocess.CalledProcessError:
        print(f"Gagal menginstal {package_name}")

# Daftar paket yang ingin diinstal
packages = ['shc', 'wget', 'curl', 'tmux']

# Instalasi setiap paket dalam daftar
for package in packages:
    install_package(package)
