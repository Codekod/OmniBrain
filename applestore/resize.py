import os
from PIL import Image

source_dir = "./"
iphone_output_dir = "./iphone_6.5/"
ipad_output_dir = "./ipad_13/"

os.makedirs(iphone_output_dir, exist_ok=True)
os.makedirs(ipad_output_dir, exist_ok=True)

# App Store Connect Standartları
IPHONE_SIZE = (1284, 2778)
IPAD_SIZE = (2048, 2732)
BACKGROUND_COLOR = (17, 19, 26) # OmniBrain koyu arka plan rengi

# Klasördeki 'IMG_' ile başlayan tüm PNG ve JPG dosyalarını otomatik listeler
valid_extensions = (".png", ".jpg", ".jpeg")
image_files = sorted([
    f for f in os.listdir(source_dir) 
    if f.lower().endswith(valid_extensions) and f.startswith("IMG_")
])

if not image_files:
    print("❌ Klasörde 'IMG_' ile başlayan herhangi bir görsel bulunamadı!")
    exit()

print(f"🎉 Klasörde {len(image_files)} adet görsel tespit edildi. Dönüştürme başlıyor...\n")

for index, img_name in enumerate(image_files, start=1):
    img_path = os.path.join(source_dir, img_name)
    
    try:
        with Image.open(img_path) as img:
            # 1. iPhone 6.5 inç Dönüşümü
            iphone_img = img.resize(IPHONE_SIZE, Image.Resampling.LANCZOS)
            iphone_img.save(os.path.join(iphone_output_dir, f"iphone_{index}.png"), "PNG")
            
            # 2. iPad 13 inç Dönüşümü (Arka plan doldurmalı)
            ipad_canvas = Image.new("RGB", IPAD_SIZE, BACKGROUND_COLOR)
            
            target_height = 2400
            aspect_ratio = img.width / img.height
            target_width = int(target_height * aspect_ratio)
            
            resized_for_ipad = img.resize((target_width, target_height), Image.Resampling.LANCZOS)
            
            x_offset = (IPAD_SIZE[0] - target_width) // 2
            y_offset = (IPAD_SIZE[1] - target_height) // 2
            ipad_canvas.paste(resized_for_ipad, (x_offset, y_offset))
            
            ipad_canvas.save(os.path.join(ipad_output_dir, f"ipad_{index}.png"), "PNG")
            print(f"✅ {img_name} başarıyla hazırlandı. (Sıra: {index})")
            
    except Exception as e:
        print(f"❌ {img_name} işlenirken hata oluştu: {e}")

print("\n🚀 Muazzam! 'iphone_6.5' ve 'ipad_13' klasörleri güncellendi. Direkt App Store Connect'e yükleyebilirsiniz.")

