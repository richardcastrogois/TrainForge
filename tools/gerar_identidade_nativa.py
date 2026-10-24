"""Reproducible native TF icons from the existing Inter brand, never an AI image."""
from pathlib import Path
import argparse,hashlib,json,struct
ROOT=Path(__file__).resolve().parents[1]
MANIFEST=ROOT/"docs/execucao/v1/native-brand-manifest.json"
FONT=ROOT/"assets/fonts/Inter-Bold.ttf"
GREEN="#215E52"; ACCENT="#D8EB90"
def owned(path):
    target=path.resolve()
    if not target.is_relative_to(ROOT.resolve()):raise ValueError("Asset outside repository")
    return target
def generate():
    from PIL import Image,ImageDraw,ImageFont
    outputs=[]
    def png(relative,size,kind):
        path=owned(ROOT/relative);path.parent.mkdir(parents=True,exist_ok=True)
        scale=4
        transparent=kind in {"foreground","monochrome","splash"}
        image=Image.new("RGBA",(size*scale,size*scale),(0,0,0,0) if transparent else GREEN)
        draw=ImageDraw.Draw(image)
        if kind=="legacy":
            image=Image.new("RGBA",(size*scale,size*scale),(0,0,0,0));draw=ImageDraw.Draw(image)
            draw.rounded_rectangle((0,0,size*scale-1,size*scale-1),radius=round(size*scale*11/34),fill=GREEN)
        font=ImageFont.truetype(str(FONT),round(size*scale*((64/288) if kind=="splash" else (0.43 if transparent else 18/34))))
        box=draw.textbbox((0,0),"TF",font=font)
        pos=((size*scale-(box[2]-box[0]))/2-box[0],(size*scale-(box[3]-box[1]))/2-box[1])
        draw.text(pos,"TF",font=font,fill="white" if kind=="monochrome" else ACCENT)
        if kind=="ios":image=image.convert("RGB")
        image.resize((size,size),Image.Resampling.LANCZOS).save(path,optimize=True)
        outputs.append({"path":relative,"width":size,"height":size,"kind":kind,"sha256":hashlib.sha256(path.read_bytes()).hexdigest()})
    png("assets/brand/app-icon.png",1024,"ios")
    for density,factor in [("mdpi",1),("hdpi",1.5),("xhdpi",2),("xxhdpi",3),("xxxhdpi",4)]:
        base="android/app/src/main/res/mipmap-"+density+"/"
        png(base+"ic_launcher.png",int(48*factor),"legacy")
        png(base+"ic_launcher_foreground.png",int(108*factor),"foreground")
        png(base+"ic_launcher_monochrome.png",int(108*factor),"monochrome")
    for density,factor in [("mdpi",1),("hdpi",1.5),("xhdpi",2),("xxhdpi",3),("xxxhdpi",4)]:
        png("android/app/src/main/res/drawable-"+density+"/tf_splash.png",int(288*factor),"splash")
    for scale,suffix in [(1,""),(2,"@2x"),(3,"@3x")]:
        png("ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage"+suffix+".png",288*scale,"splash")
    directory=ROOT/"ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for item in json.loads((directory/"Contents.json").read_text())["images"]:
        if "filename" not in item:continue
        size=int(float(item["size"].split("x")[0])*float(item["scale"].removesuffix("x")))
        png((directory/item["filename"]).relative_to(ROOT).as_posix(),size,"ios")
    MANIFEST.write_text(json.dumps({"source":"Existing TrainForge TF mark, Inter Bold 4.1","fontSha256":hashlib.sha256(FONT.read_bytes()).hexdigest(),
        "colors":{"background":GREEN,"foreground":ACCENT},"generator":"tools/gerar_identidade_nativa.py","files":outputs},indent=2)+"\n",encoding="utf-8")
    print("Generated native brand files:",len(outputs))
def check():
    data=json.loads(MANIFEST.read_text())
    for row in data["files"]:
        path=owned(ROOT/row["path"]);blob=path.read_bytes()
        if blob[:8]!=b"\x89PNG\r\n\x1a\n" or struct.unpack(">II",blob[16:24])!=(row["width"],row["height"]):raise ValueError("PNG dimensions differ")
        if hashlib.sha256(blob).hexdigest()!=row["sha256"]:raise ValueError("Brand asset hash differs")
    if hashlib.sha256(FONT.read_bytes()).hexdigest()!=data["fontSha256"]:raise ValueError("Font provenance differs")
    print("Verified native brand files:",len(data["files"]))
if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("--write",action="store_true")
    args=parser.parse_args()
    if args.write:generate()
    check()
