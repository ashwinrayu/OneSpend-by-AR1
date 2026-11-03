import os
from PIL import Image, ImageDraw, ImageFont

def create_master_icon(size=1024, is_foreground=False):
    # If foreground, transparent background
    if is_foreground:
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    else:
        # Obsidian dark canvas #0F1115
        img = Image.new('RGBA', (size, size), (15, 17, 21, 255))
    
    draw = ImageDraw.Draw(img)
    
    # Adaptive safe zone: 66% of size = 675px centered
    # Center = 512, 512
    cx, cy = size // 2, size // 2
    
    # Draw badge container
    badge_w = int(size * 0.62)
    badge_h = int(size * 0.62)
    x0 = cx - badge_w // 2
    y0 = cy - badge_h // 2
    x1 = cx + badge_w // 2
    y1 = cy + badge_h // 2
    radius = int(size * 0.16)
    
    # Inner surface #181C24
    draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=(24, 28, 36, 255), outline=(16, 185, 129, 255), width=int(size * 0.022))
    
    # Inner subtle glow border
    glow_margin = int(size * 0.025)
    draw.rounded_rectangle(
        [x0 + glow_margin, y0 + glow_margin, x1 - glow_margin, y1 - glow_margin],
        radius=radius - glow_margin,
        outline=(16, 185, 129, 60),
        width=int(size * 0.008)
    )

    # Load font
    font_path = 'C:\\Windows\\Fonts\\segoeuib.ttf'
    font_size_main = int(size * 0.26)
    font_size_bracket = int(size * 0.29)
    font_size_sub = int(size * 0.055)
    
    font_main = ImageFont.truetype(font_path, font_size_main)
    font_bracket = ImageFont.truetype(font_path, font_size_bracket)
    font_sub = ImageFont.truetype(font_path, font_size_sub)
    
    # Monogram [ 1S ]
    # Draw brackets in emerald #10B981, "1S" in white #FFFFFF
    # Let's measure text components
    text_lbracket = "["
    text_code = "1S"
    text_rbracket = "]"
    
    lb_bbox = draw.textbbox((0, 0), text_lbracket, font=font_bracket)
    lb_w = lb_bbox[2] - lb_bbox[0]
    
    code_bbox = draw.textbbox((0, 0), text_code, font=font_main)
    code_w = code_bbox[2] - code_bbox[0]
    code_h = code_bbox[3] - code_bbox[1]
    
    rb_bbox = draw.textbbox((0, 0), text_rbracket, font=font_bracket)
    rb_w = rb_bbox[2] - rb_bbox[0]
    
    spacing = int(size * 0.03)
    total_w = lb_w + spacing + code_w + spacing + rb_w
    
    start_x = cx - total_w // 2
    text_y = cy - int(size * 0.07) - code_h // 2
    
    # Left bracket
    draw.text((start_x, text_y - int(size * 0.015)), text_lbracket, font=font_bracket, fill=(16, 185, 129, 255))
    
    # Center "1S"
    code_x = start_x + lb_w + spacing
    draw.text((code_x, text_y), text_code, font=font_main, fill=(255, 255, 255, 255))
    
    # Right bracket
    rb_x = code_x + code_w + spacing
    draw.text((rb_x, text_y - int(size * 0.015)), text_rbracket, font=font_bracket, fill=(16, 185, 129, 255))
    
    # Subtitle "ONESPEND"
    sub_text = "ONESPEND"
    sub_bbox = draw.textbbox((0, 0), sub_text, font=font_sub)
    sub_w = sub_bbox[2] - sub_bbox[0]
    sub_x = cx - sub_w // 2
    sub_y = cy + int(size * 0.14)
    draw.text((sub_x, sub_y), sub_text, font=font_sub, fill=(16, 185, 129, 220))
    
    # Accent emerald bar under "ONESPEND"
    bar_w = int(size * 0.12)
    bar_h = int(size * 0.01)
    bar_x0 = cx - bar_w // 2
    bar_y0 = sub_y + int(size * 0.08)
    draw.rounded_rectangle([bar_x0, bar_y0, bar_x0 + bar_w, bar_y0 + bar_h], radius=bar_h//2, fill=(16, 185, 129, 255))
    
    return img

def main():
    os.makedirs('assets/icons', exist_ok=True)
    os.makedirs('windows/runner/resources', exist_ok=True)
    
    print('Generating Master App Icon (1024x1024)...')
    master_icon = create_master_icon(1024, is_foreground=False)
    master_icon.save('assets/icons/app_icon.png', format='PNG')
    
    print('Generating Adaptive Foreground Icon (1024x1024)...')
    foreground_icon = create_master_icon(1024, is_foreground=True)
    foreground_icon.save('assets/icons/app_icon_foreground.png', format='PNG')
    
    print('Generating Windows app_icon.ico (Multi-resolution 16-256)...')
    ico_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    master_icon.save(
        'windows/runner/resources/app_icon.ico',
        format='ICO',
        sizes=ico_sizes
    )
    
    # Generate Android mipmap densities
    android_densities = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    
    res_base = 'android/app/src/main/res'
    for folder, dim in android_densities.items():
        folder_path = os.path.join(res_base, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        # Standard launcher icon
        resized = master_icon.resize((dim, dim), Image.Resampling.LANCZOS)
        resized.save(os.path.join(folder_path, 'ic_launcher.png'), format='PNG')
        resized.save(os.path.join(folder_path, 'ic_launcher_round.png'), format='PNG')
        
        # Adaptive foreground
        fg_dim = int(dim * 1.5) # adaptive foreground is typically 108dp on 72dp viewport
        fg_resized = foreground_icon.resize((fg_dim, fg_dim), Image.Resampling.LANCZOS)
        fg_resized.save(os.path.join(folder_path, 'ic_launcher_foreground.png'), format='PNG')
        print(f'Generated Android {folder} ({dim}x{dim})')
        
    print('Icon generation complete!')

if __name__ == '__main__':
    main()
