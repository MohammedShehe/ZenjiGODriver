import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/api/driver_api.dart';
import '../core/widgets.dart';
import 'main_shell.dart';
import 'registration.dart';

class DriverLoginScreen extends StatefulWidget {
 const DriverLoginScreen({super.key});
 @override State<DriverLoginScreen> createState()=>_DriverLoginScreenState();
}
class _DriverLoginScreenState extends State<DriverLoginScreen>{
 final phone=TextEditingController(); final otp=TextEditingController(); bool sent=false,loading=false; int seconds=0; Timer? timer;
 @override void dispose(){phone.dispose();otp.dispose();timer?.cancel();super.dispose();}
 Future<void> send() async{
  if(phone.text.trim().length<7){toast(context,'Enter a valid phone number.');return;}
  setState(()=>loading=true);
  try{await DriverApi.sendOtp('+255${phone.text.trim()}');if(mounted){setState(()=>sent=true);start();toast(context,'OTP sent.');}}catch(e){if(mounted)toast(context,e.toString().replaceFirst('Exception: ',''));}finally{if(mounted)setState(()=>loading=false);}
 }
 void start(){timer?.cancel();seconds=60;timer=Timer.periodic(const Duration(seconds:1),(t){if(!mounted||seconds<=1){t.cancel();if(mounted)setState(()=>seconds=0);return;}setState(()=>seconds--);});}
 Future<void> verify() async{
  final appState = AppScope.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if(otp.text.trim().length<4){toast(context,'Enter the OTP.');return;}setState(()=>loading=true);
  try{final d=await DriverApi.login('+255${phone.text.trim()}',otp.text.trim());if(!mounted)return;await appState.login(d);if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const MainShell()));}
  catch(e){if(mounted && messenger != null){messenger.showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));}}finally{if(mounted)setState(()=>loading=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Driver sign in')),body:ResponsivePage(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
  const SizedBox(height:20),Text('Welcome back',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),
  const SizedBox(height:8),const Text('Sign in with your registered Tanzania phone number.'),
  const SizedBox(height:24),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Phone number',prefixText:'+255 ')),
  const SizedBox(height:12),
  if(!sent) LoadingButton(label:'Send OTP',onPressed:send) else ...[
   TextField(controller:otp,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'OTP')),
   const SizedBox(height:8),Text(seconds>0?'Resend in $seconds s':'You can resend the OTP.'),
   const SizedBox(height:12),LoadingButton(label:'Verify & sign in',onPressed:verify),
  ],
  const SizedBox(height:24),OutlinedButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RegistrationScreen())),child:const Text('Register as a driver')),
 ])));
}
