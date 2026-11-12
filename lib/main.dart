import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(const CampaignApp());
const bg = Color(0xFF071D25);
const surface = Color(0xFF10343B);
const mint = Color(0xFF9DD9CA);
const cream = Color(0xFFF8F1DA);

enum Format { avatar, banner }

class CampaignApp extends StatelessWidget {
  const CampaignApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Projetando 2027',
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: mint, brightness: Brightness.dark),
      scaffoldBackgroundColor: bg),
    home: const CampaignPage(),
  );
}

class CampaignPage extends StatefulWidget {
  const CampaignPage({super.key});
  @override
  State<CampaignPage> createState() => _CampaignPageState();
}

class _CampaignPageState extends State<CampaignPage> {
  Format format = Format.avatar;
  ui.Image? photo, frame;
  double zoom = 1, initialZoom = 1;
  Offset offset = Offset.zero, initialOffset = Offset.zero, initialFocal = Offset.zero;
  bool busy = false;
  final preview = GlobalKey();
  int get width => format == Format.avatar ? 1080 : 1920;
  int get height => 1080;

  @override
  void initState() { super.initState(); loadFrame(); }
  @override
  void dispose() { photo?.dispose(); frame?.dispose(); super.dispose(); }

  Future<ui.Image> decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final result = await codec.getNextFrame();
    codec.dispose();
    return result.image;
  }

  Future<void> loadFrame() async {
    final requested = format;
    try {
      final data = await rootBundle.load('assets/frames/' + requested.name + '.png');
      final decoded = await decode(data.buffer.asUint8List());
      if (!mounted || requested != format) { decoded.dispose(); return; }
      setState(() { frame?.dispose(); frame = decoded; });
    } catch (_) {
      if (!mounted || requested != format) return;
      setState(() { frame?.dispose(); frame = null; });
    }
  }

  void select(Format f) {
    if (f == format) return;
    setState(() {
      format = f;
      frame?.dispose();
      frame = null;
      zoom = 1;
      offset = Offset.zero;
    });
    loadFrame();
  }

  void message(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> upload() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.first.bytes;
      if (bytes == null) throw Exception('Arquivo inválido.');
      if (bytes.length > 20 * 1024 * 1024) throw Exception('Limite de 20 MB.');
      final decoded = await decode(bytes);
      if (!mounted) { decoded.dispose(); return; }
      setState(() {
        photo?.dispose();
        photo = decoded;
        zoom = 1;
        offset = Offset.zero;
      });
    } catch (e) { message('Erro ao carregar foto: ' + e.toString()); }
  }

  Future<void> download() async {
    if (photo == null || busy) return;
    setState(() => busy = true);
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(width.toDouble(), height.toDouble());
      final render = preview.currentContext?.findRenderObject() as RenderBox?;
      final scale = width / (render?.size.width ?? width);
      ArtPainter.paintArt(canvas, size, photo, frame, zoom, offset * scale);
      final output = await recorder.endRecording().toImage(width, height);
      final data = await output.toByteData(format: ui.ImageByteFormat.png);
      output.dispose();
      if (data == null) throw Exception('Erro de exportação.');
      final blob = html.Blob([data.buffer.asUint8List()], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..download = 'projetando-2027-' + format.name + '.png'
        ..click();
      Future.delayed(const Duration(seconds: 2), () => html.Url.revokeObjectUrl(url));
      message('Arte pronta! Compartilhe a campanha.');
    } catch (e) { message('Falha no download: ' + e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(body: SingleChildScrollView(child: Column(children: [
      Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: wide ? 60 : 20, vertical: 23),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF2C5055)))),
        child: const Row(children: [
          Icon(Icons.auto_awesome, color: mint),
          SizedBox(width: 12),
          Expanded(child: Text('REMANESCENTES', style: TextStyle(color: cream, letterSpacing: 2, fontSize: 13, fontWeight: FontWeight.w900))),
          Text('2027', style: TextStyle(color: mint, fontWeight: FontWeight.w900)),
        ]),
      ),
      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(padding: EdgeInsets.all(wide ? 45 : 20),
          child: wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(child: intro()), const SizedBox(width: 60), Expanded(child: editor()),
                ])
              : Column(children: [intro(), const SizedBox(height: 33), editor()]),
        )),
      const Padding(padding: EdgeInsets.all(28),
        child: Text('PROJETANDO 2027  •  IGREJA REMANESCENTES',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, letterSpacing: 1.3, color: Color(0xFF88A6A7)))),
    ])));
  }

  Widget intro() => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('CAMPANHA 2027', style: TextStyle(color: mint, letterSpacing: 4, fontWeight: FontWeight.w800)),
    SizedBox(height: 15),
    Text('O FUTURO\nCOMEÇA COM\nUMA VISÃO.',
      style: TextStyle(color: cream, fontSize: 44, fontWeight: FontWeight.w900, height: 1.12, letterSpacing: -1.4)),
    SizedBox(height: 20),
    Text('Estamos projetando 2027. Um novo tempo de sonhos, propósitos e realizações. Faça parte desse movimento.',
      style: TextStyle(color: Color(0xFFBDD0CD), fontSize: 16, height: 1.6)),
    SizedBox(height: 22),
    Row(children: [
      Icon(Icons.check_circle_outline, color: mint, size: 20),
      SizedBox(width: 8),
      Expanded(child: Text('Crie sua foto e compartilhe essa visão.',
        style: TextStyle(color: cream, fontWeight: FontWeight.w600))),
    ]),
  ]);

  Widget editor() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: surface, border: Border.all(color: const Color(0xFF2B535A)),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [BoxShadow(blurRadius: 28, color: Color(0x44000000), offset: Offset(0, 15))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Personalize sua foto', style: TextStyle(color: cream, fontWeight: FontWeight.w900, fontSize: 22)),
      const SizedBox(height: 6),
      const Text('Escolha o formato, envie sua foto e baixe a arte.',
        style: TextStyle(color: Color(0xFFBAD0CC), fontSize: 13)),
      const SizedBox(height: 18),
      Row(children: Format.values.map((f) {
        final active = f == format;
        return Expanded(child: Padding(
          padding: EdgeInsets.only(right: f == Format.avatar ? 8 : 0),
          child: OutlinedButton.icon(onPressed: () => select(f),
            icon: Icon(f == Format.avatar ? Icons.account_circle_outlined : Icons.wallpaper_outlined, size: 18),
            label: Text(f == Format.avatar ? 'Avatar' : 'Banner'),
            style: OutlinedButton.styleFrom(
              foregroundColor: active ? bg : cream,
              backgroundColor: active ? mint : const Color(0xFF1B4147),
              side: BorderSide(color: active ? mint : const Color(0xFF55757B)),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)))),
        ));
      }).toList()),
      const SizedBox(height: 15),
      AspectRatio(aspectRatio: width / height,
        child: ClipRRect(borderRadius: BorderRadius.circular(13),
          child: GestureDetector(
            onScaleStart: photo == null ? null : (d) {
              initialZoom = zoom; initialOffset = offset; initialFocal = d.focalPoint;
            },
            onScaleUpdate: photo == null ? null : (d) => setState(() {
              zoom = (initialZoom * d.scale).clamp(1.0, 4.0);
              offset = initialOffset + d.focalPoint - initialFocal;
            }),
            child: CustomPaint(key: preview,
              painter: ArtPainter(photo: photo, frame: frame, zoom: zoom, offset: offset),
              child: photo == null ? const Center(child: Column(
                mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_photo_alternate_outlined, color: cream, size: 36),
                  SizedBox(height: 9),
                  Text('Sua foto aparecerá aqui', style: TextStyle(color: cream)),
                ])) : null),
          ))),
      if (frame == null) const Padding(padding: EdgeInsets.only(top: 8),
        child: Text('Arte provisória: aguardando moldura PNG oficial.',
          style: TextStyle(color: Color(0xFFF2D18A), fontSize: 12))),
      if (photo != null) ...[
        const SizedBox(height: 12),
        const Text('Arraste para ajustar a posição e o zoom.',
          style: TextStyle(fontSize: 12, color: Color(0xFFB9CBC8))),
        Row(children: [
          const Icon(Icons.zoom_out, color: mint, size: 19),
          Expanded(child: Slider(value: zoom, min: 1, max: 4,
            onChanged: (v) => setState(() => zoom = v))),
          const Icon(Icons.zoom_in, color: mint, size: 19),
          IconButton(tooltip: 'Redefinir', onPressed: () => setState(() {
            zoom = 1; offset = Offset.zero;
          }), icon: const Icon(Icons.restart_alt)),
        ]),
      ],
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: upload,
        icon: Icon(photo == null ? Icons.upload_file : Icons.refresh),
        label: Text(photo == null ? 'Escolher minha foto' : 'Trocar foto'),
        style: FilledButton.styleFrom(backgroundColor: cream, foregroundColor: bg,
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))))),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: photo == null || busy ? null : download,
        icon: const Icon(Icons.download_rounded),
        label: Text(busy ? 'Gerando imagem...' : 'Baixar minha arte em PNG'),
        style: OutlinedButton.styleFrom(foregroundColor: mint,
          side: const BorderSide(color: mint),
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))))),
      const SizedBox(height: 10),
      const Center(child: Text('Sua foto não é enviada para servidores.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Color(0xFF96B6B2)))),
    ]),
  );
}

class ArtPainter extends CustomPainter {
  ArtPainter({required this.photo, required this.frame, required this.zoom, required this.offset});
  final ui.Image? photo, frame;
  final double zoom;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) => paintArt(canvas, size, photo, frame, zoom, offset);

  static void paintArt(Canvas canvas, Size size, ui.Image? photo, ui.Image? frame, double zoom, Offset offset) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF285459));
    if (photo != null) {
      final natural = Size(photo.width.toDouble(), photo.height.toDouble());
      final cover = math.max(size.width / natural.width, size.height / natural.height);
      final destination = Rect.fromCenter(center: size.center(Offset.zero) + offset,
        width: natural.width * cover * zoom, height: natural.height * cover * zoom);
      canvas.save();
      canvas.clipRect(Offset.zero & size);
      canvas.drawImageRect(photo, Offset.zero & natural, destination,
        Paint()..filterQuality = FilterQuality.high);
      canvas.restore();
    }
    if (frame != null) {
      canvas.drawImageRect(frame,
        Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble()),
        Offset.zero & size, Paint()..filterQuality = FilterQuality.high);
    } else {
      canvas.save();
      canvas.scale(size.width / 1080, size.height / 1080);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 1080, 15), Paint()..color = mint);
      canvas.drawRect(const Rect.fromLTWH(0, 1065, 1080, 15), Paint()..color = mint);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 15, 1080), Paint()..color = mint);
      canvas.drawRect(const Rect.fromLTWH(1065, 0, 15, 1080), Paint()..color = mint);
      canvas.drawRect(const Rect.fromLTWH(0, 843, 1080, 222),
        Paint()..color = const Color(0xE0071D25));
      write(canvas, 'PROJETANDO', const Offset(68, 867), 73, cream);
      write(canvas, '2027', const Offset(68, 952), 80, mint);
      write(canvas, 'IGREJA REMANESCENTES', const Offset(676, 1018), 20, cream);
      canvas.restore();
    }
  }

  static void write(Canvas canvas, String s, Offset point, double size, Color color) {
    final painter = TextPainter(textDirection: TextDirection.ltr,
      text: TextSpan(text: s,
        style: TextStyle(fontSize: size, fontWeight: FontWeight.w900,
          letterSpacing: -1, color: color)))..layout();
    painter.paint(canvas, point);
  }

  @override
  bool shouldRepaint(covariant ArtPainter old) =>
    old.photo != photo || old.frame != frame || old.zoom != zoom || old.offset != offset;
}
