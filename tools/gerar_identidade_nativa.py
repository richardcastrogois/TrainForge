"""Reproducible native TF icons from the "Batimento" monogram, drawn from code, never an AI image."""
from pathlib import Path
import argparse,hashlib,json,struct
ROOT=Path(__file__).resolve().parents[1]
MANIFEST=ROOT/"docs/execucao/v1/native-brand-manifest.json"
FONT=ROOT/"assets/fonts/Inter-Bold.ttf"
GREEN="#215E52"; ACCENT="#D8EB90"; DEEP="#174639"
# Same strokes as lib/core/theme/brand_mark.dart (120x120 box, skewX(-9deg), centred).
STROKES=[[(20,37),(100,37)],[(44,37),(44,97)],[(74,37),(74,97)],[(74,67),(82,67),(87,56),(94,80),(99,67),(107,67)]]
def glyph(draw,left,top,box,color):
    k=box/120
    def at(x,y):return (left+(x-0.15838*y+5.7)*k,top+(y-7)*k)
    width=11*k
    for stroke in STROKES:
        points=[at(x,y) for x,y in stroke]
        for (ax,ay),(bx,by) in zip(points,points[1:]):
            length=((bx-ax)**2+(by-ay)**2)**.5;nx,ny=-(by-ay)/length*width/2,(bx-ax)/length*width/2
            draw.polygon([(ax+nx,ay+ny),(bx+nx,by+ny),(bx-nx,by-ny),(ax-nx,ay-ny)],fill=color)
        for px,py in points:draw.ellipse((px-width/2,py-width/2,px+width/2,py+width/2),fill=color)
def owned(path):
    target=path.resolve()
    if not target.is_relative_to(ROOT.resolve()):raise ValueError("Asset outside repository")
    return target
def generate():
    from PIL import Image,ImageDraw
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
        side=size*scale
        if kind=="splash":
            tile=side*124/288;x0=(side-tile)/2
            draw.rounded_rectangle((x0,x0,x0+tile,x0+tile),radius=round(tile*38/124),fill=DEEP)
            glyph(draw,x0+tile*.1,x0+tile*.1,tile*.8,ACCENT)
        else:
            box=side*(0.8 if kind=="legacy" else 0.72 if kind=="ios" else 0.62)
            glyph(draw,(side-box)/2,(side-box)/2,box,"white" if kind=="monochrome" else ACCENT)
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
    MANIFEST.write_text(json.dumps({"source":"TrainForge Batimento monogram (code-drawn strokes)","fontSha256":hashlib.sha256(FONT.read_bytes()).hexdigest(),
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
