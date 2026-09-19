import 'package:flutter/material.dart';
import 'theme.dart';

class MockMap extends StatelessWidget {
  final double height; final bool active; final bool showRequests;
  const MockMap({super.key, this.height = 360, this.active = false, this.showRequests = true});
  @override Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(24), child: SizedBox(height: height, width: double.infinity, child: CustomPaint(painter: _MapPainter(Theme.of(context).brightness == Brightness.dark), child: Stack(children:[
    Positioned(right:14,top:14,child:Column(children:[_MapButton(Icons.my_location),const SizedBox(height:8),_MapButton(Icons.layers_outlined)])),
    if(showRequests)...[
      const Positioned(left:44,top:64,child:_Pin(icon:Icons.person_pin_circle, label:'Rider')),
      const Positioned(right:90,top:142,child:_Pin(icon:Icons.person_pin_circle, label:'Rider')),
      const Positioned(left:108,bottom:72,child:_Pin(icon:Icons.person_pin_circle, label:'Rider')),
    ],
    if(active)...[
      const Positioned(left:45,bottom:48,child:_Pin(icon:Icons.trip_origin,label:'Pickup',green:true)),
      const Positioned(right:55,top:72,child:_Pin(icon:Icons.location_on,label:'Drop-off',green:true)),
      Center(child:Transform.rotate(angle:-.35,child:const Icon(Icons.local_taxi_rounded,size:34,color:ZenjiColors.green))),
    ],
    Positioned(left:14,bottom:14,child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface.withValues(alpha:.92),borderRadius:BorderRadius.circular(12)),child:const Row(children:[Icon(Icons.navigation_rounded,size:17,color:ZenjiColors.green),SizedBox(width:6),Text('Stone Town, Zanzibar',style:TextStyle(fontWeight:FontWeight.w700,fontSize:12))]))),
  ]))));
}

class _MapButton extends StatelessWidget { final IconData icon; const _MapButton(this.icon); @override Widget build(BuildContext context)=>Container(width:42,height:42,decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(13),boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.08),blurRadius:8)]),child:Icon(icon,size:20)); }
class _Pin extends StatelessWidget { final IconData icon;final String label;final bool green;const _Pin({required this.icon,required this.label,this.green=false});@override Widget build(BuildContext context)=>Column(children:[Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:green?ZenjiColors.green:Theme.of(context).colorScheme.primary,shape:BoxShape.circle),child:Icon(icon,color:Colors.white,size:20)),Container(margin:const EdgeInsets.only(top:3),padding:const EdgeInsets.symmetric(horizontal:7,vertical:3),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(8)),child:Text(label,style:const TextStyle(fontSize:10,fontWeight:FontWeight.bold))) ]);}
class _MapPainter extends CustomPainter { final bool dark; _MapPainter(this.dark); @override void paint(Canvas c,Size s){final bg=Paint()..color=dark?const Color(0xFF102A44):const Color(0xFFEAF2F1);c.drawRect(Offset.zero&s,bg); final road=Paint()..color=(dark?const Color(0xFF31506C):Colors.white)..strokeWidth=12..style=PaintingStyle.stroke..strokeCap=StrokeCap.round; final thin=Paint()..color=(dark?const Color(0xFF233F59):const Color(0xFFD6E3E3))..strokeWidth=5..style=PaintingStyle.stroke; final p=Path()..moveTo(-30,s.height*.72)..cubicTo(s.width*.25,s.height*.55,s.width*.42,s.height*.8,s.width+30,s.height*.35);c.drawPath(p,road);final p2=Path()..moveTo(s.width*.15,-20)..cubicTo(s.width*.35,s.height*.25,s.width*.12,s.height*.65,s.width*.5,s.height+20);c.drawPath(p2,thin);final p3=Path()..moveTo(s.width*.72,-20)..cubicTo(s.width*.54,s.height*.25,s.width*.92,s.height*.52,s.width*.7,s.height+20);c.drawPath(p3,thin);for(var i=0;i<7;i++){final x=(i*93.0)%s.width;final y=(i*57.0)%s.height;c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,55,32),const Radius.circular(7)),Paint()..color=(dark?Colors.white:ZenjiColors.teal).withValues(alpha:.05));}}
@override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;}
