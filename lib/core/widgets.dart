import 'package:flutter/material.dart';
import 'app_state.dart';
import 'theme.dart';

class ResponsivePage extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  const ResponsivePage({super.key, required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12), this.maxWidth = 720});
  @override
  Widget build(BuildContext context) => SafeArea(child: LayoutBuilder(builder: (context, c) => SingleChildScrollView(padding: padding, child: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth, minWidth: 0), child: child)))));
}

class ZenjiLogo extends StatelessWidget {
  final double height;
  const ZenjiLogo({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/logos/logo_dark.png'
        : 'assets/logos/logo_light.png';

    return Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => Icon(
        Icons.local_taxi_rounded,
        size: height * .8,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title; final String? action; final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10, top: 4), child: Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))), if(action != null) TextButton(onPressed: onAction, child: Text(action!))]));
}

class LoadingButton extends StatefulWidget {
  final String label; final IconData? icon; final Future<void> Function()? onPressed; final bool outline;
  const LoadingButton({super.key, required this.label, this.icon, this.onPressed, this.outline = false});
  @override State<LoadingButton> createState() => _LoadingButtonState();
}
class _LoadingButtonState extends State<LoadingButton> {
  bool loading = false;
  Future<void> tap() async { if (widget.onPressed == null || loading) return; setState(() => loading = true); try { await widget.onPressed!(); } finally { if(mounted) setState(() => loading = false); } }
  @override Widget build(BuildContext context) {
    final child = loading ? const SizedBox.square(dimension: 21, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [if(widget.icon != null)...[Icon(widget.icon, size: 20), const SizedBox(width: 8)], Text(widget.label)]);
    if(widget.outline) return SizedBox(width: double.infinity, height: 54, child: OutlinedButton(onPressed: widget.onPressed == null ? null : tap, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: child));
    return ElevatedButton(onPressed: widget.onPressed == null ? null : tap, child: child);
  }
}

class Pill extends StatelessWidget {
  final String text; final Color? color; final IconData? icon;
  const Pill(this.text, {super.key, this.color, this.icon});
  @override Widget build(BuildContext context) { final c = color ?? Theme.of(context).colorScheme.primary; return Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: c.withValues(alpha: .13), borderRadius: BorderRadius.circular(99)), child: Row(mainAxisSize: MainAxisSize.min, children: [if(icon != null)...[Icon(icon, size: 14, color: c), const SizedBox(width: 5)], Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12))])); }
}

Future<void> fakeDelay([int ms = 650]) => Future.delayed(Duration(milliseconds: ms));

void toast(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

Future<bool?> confirmDialog(BuildContext context, {required String title, required String message, String confirm = 'Confirm'}) => showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Cancel')), FilledButton(onPressed: ()=>Navigator.pop(context,true), child: Text(confirm))]));

class ThemeLanguageRow extends StatelessWidget {
  const ThemeLanguageRow({super.key});
  @override Widget build(BuildContext context) { final s=AppScope.of(context); final dark=Theme.of(context).brightness==Brightness.dark; return Row(mainAxisAlignment: MainAxisAlignment.end, children:[PopupMenuButton<bool>(tooltip:'Language', initialValue:s.isSwahili, onSelected:s.setLanguage, itemBuilder:(_)=>const[PopupMenuItem(value:false,child:Text('English')),PopupMenuItem(value:true,child:Text('Kiswahili'))], child:Pill(s.isSwahili?'Kiswahili':'English',icon:Icons.language)), const SizedBox(width:8), IconButton.filledTonal(onPressed:()=>s.toggleTheme(!dark), icon:Icon(dark?Icons.light_mode_rounded:Icons.dark_mode_rounded))]); }
}

class KeyValueRow extends StatelessWidget {
  final String label, value; const KeyValueRow(this.label,this.value,{super.key});
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[SizedBox(width:120,child:Text(label,style:TextStyle(color:Theme.of(context).colorScheme.onSurface.withValues(alpha:.62)))),Expanded(child:Text(value,style:const TextStyle(fontWeight:FontWeight.w700))) ]));
}

class EmptyState extends StatelessWidget {
  final IconData icon; final String title, subtitle; const EmptyState({super.key,required this.icon,required this.title,required this.subtitle});
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.all(28),child:Column(children:[Icon(icon,size:52,color:Theme.of(context).colorScheme.primary),const SizedBox(height:12),Text(title,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:6),Text(subtitle,textAlign:TextAlign.center,style:TextStyle(color:Theme.of(context).colorScheme.onSurface.withValues(alpha:.65))) ]));
}
