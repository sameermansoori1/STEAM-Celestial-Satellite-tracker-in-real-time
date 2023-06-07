import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:steam_celestial_satellite_tracker_in_real_time/screens/lg_settings.dart';
import 'package:steam_celestial_satellite_tracker_in_real_time/utils/colors.dart';
import 'package:steam_celestial_satellite_tracker_in_real_time/utils/snackbar.dart';

import '../services/lg_service.dart';
import '../services/ssh_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/custom_page_route.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {

  bool val = false, tools=false, lgConnected=false;
  bool _settingRefresh = false, _resetingRefresh = false, _clearingKml = false, _rebooting = false, _relaunching = false, _shuttingDown = false;

  SSHService get _sshService => GetIt.I<SSHService>();
  LGService get _lgService => GetIt.I<LGService>();

  @override
  void initState() {
    checkLGConnection();
    super.initState();
  }

  @override
  void setState(fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  Future<void> checkLGConnection() async{
    final result = await _sshService.connect();
    if (result != 'session_connected'){
      setState(() {
        lgConnected=false;
      });
    }
    else{
      setState(() {
        lgConnected=true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(
        elevation: 3,
        title: const Text('Settings'),
        backgroundColor: ThemeColors.primaryColor,
        foregroundColor: ThemeColors.backgroundColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 20, 0, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 20, 10),
                child: _buildSection('INFO')
              ),
              ListTile(
                  title: _buildTitle('About'),
                  leading: _buildIcon(Icons.info_outline),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 20, 10),
                child: _buildSection('APP SETTINGS')
              ),
              ListTile(
                leading: _buildIcon(Icons.dark_mode_outlined),
                title: _buildTitle('Dark Mode'),
                trailing: Switch(
                  activeColor: ThemeColors.primaryColor,
                  onChanged: (value){
                    setState(() {
                      val=value;
                    });
                  },
                  value: val,
                ),
              ),
              _divider(),
              ListTile(
                  title: _buildTitle('Bluetooth Connection'),
                  leading: _buildIcon(Icons.settings_bluetooth_outlined),
                  trailing: const Icon(Icons.arrow_forward,),
              ),
              _divider(),
              ListTile(
                onTap: (){
                  Navigator.of(context).push(
                      CustomPageRoute(child: const LGSettings())
                  );
                },
                title: _buildTitle('LG Connection'),
                leading: Image.asset('assets/lg.png',width: 20,height: 20,color: ThemeColors.primaryColor,),
                trailing: const Icon(Icons.arrow_forward,),
                ),
              _divider(),
              ListTile(
                onTap: (){
                  setState(() {
                    tools=!tools;
                  });
                },
                title: Text('LG Tools',style: TextStyle(color: ThemeColors.textPrimary,fontSize: 20,fontWeight: tools ? FontWeight.bold : FontWeight.normal),overflow: TextOverflow.visible,),
                leading: _buildIcon(Icons.settings_input_antenna),
                trailing: tools ?
                     Icon(Icons.keyboard_arrow_up,color: ThemeColors.primaryColor,) :
                     const Icon(Icons.keyboard_arrow_down,)
              ),
              tools ? showTools() : _divider()
            ],
          ),
        ),
      )
    );
  }
  Widget _buildTitle(String title){
    return Text(title,style: TextStyle(color: ThemeColors.textPrimary,fontSize: 20),overflow: TextOverflow.visible,);
  }
  Widget _buildIcon(IconData iconData){
    return Icon(iconData,size: 20,color: ThemeColors.primaryColor,);
  }
  Widget _buildSection(String title){
    return Text(title,style: TextStyle(color: ThemeColors.secondaryColor,fontWeight: FontWeight.bold,overflow: TextOverflow.ellipsis),);
  }
  Widget _divider(){
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 0.2,
      color: ThemeColors.dividerColor,
      margin: const EdgeInsets.only(left: 75),
    );
  }

  Widget showTools(){
    ButtonStyle style = ElevatedButton.styleFrom(backgroundColor: ThemeColors.primaryColor,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)));
    ButtonStyle _style = ElevatedButton.styleFrom(backgroundColor: ThemeColors.secondaryColor,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)));
    return Padding(
      padding: const EdgeInsets.only(right: 10,left: 5,top: 10),
      child: Column(
        children: [
          ElevatedButton(
              onPressed: () {
                checkLGConnection();
                if(!lgConnected){
                  errorTaskButton();
                }else{

                  if (_settingRefresh) {
                    return;
                  }

                  showDialog(
                    context: context,
                    builder: (context) => ConfirmDialog(
                      title: 'Are you sure?',
                      message:
                      'The slaves solo KMLs will start to refresh each 2 seconds and all screens will be rebooted.',
                      onCancel: () {
                        Navigator.of(context).pop();
                      },
                      onConfirm: () async {
                        Navigator.of(context).pop();

                        setState(() {
                          _settingRefresh = true;
                        });

                        try {
                          await _lgService.setRefresh();
                        } finally {
                          setState(() {
                            _settingRefresh = false;
                          });
                        }
                      },
                    ),
                  );
                }
              },
              style: style,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buttonText('SET SLAVES REFRESH'),
                const SizedBox(
                  width: 5,
                ),
                _settingRefresh
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3,color: ThemeColors.backgroundColor,),
                      )
                    : const SizedBox()
              ],
            ),
          ),
          const SizedBox(height: 5,),
          ElevatedButton(
            onPressed: (){
              checkLGConnection();
              if(!lgConnected){
                errorTaskButton();
              }else{

                if (_resetingRefresh) {
                  return;
                }

                showDialog(
                  context: context,
                  builder: (context) => ConfirmDialog(
                    title: 'Are you sure?',
                    message:
                    'The slaves will stop refreshing and all screens will be rebooted.',
                    onCancel: () {
                      Navigator.of(context).pop();
                    },
                    onConfirm: () async {
                      Navigator.of(context).pop();

                      setState(() {
                        _resetingRefresh = true;
                      });

                      try {
                        await _lgService.resetRefresh();
                      } finally {
                        setState(() {
                          _resetingRefresh = false;
                        });
                      }
                    },
                  ),
                );
              }
            },
            style: style,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buttonText('RESET SLAVES REFRESH'),
                const SizedBox(
                  width: 5,
                ),
                _resetingRefresh
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3,color: ThemeColors.backgroundColor),
                      )
                    : const SizedBox()
              ],
            ),
          ),
          const SizedBox(height: 5,),
          ElevatedButton(
            onPressed: () async {
              checkLGConnection();
              if(!lgConnected){
                errorTaskButton();
              }else{

                if (_clearingKml) {
                  return;
                }

                setState(() {
                  _clearingKml = true;
                });

                try {
                  await _lgService.clearKml(keepLogos: false);
                } finally {
                  setState(() {
                    _clearingKml = false;
                  });
                }
              }
            },
            style: style,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buttonText('CLEAR KML + LOGOS'),
                const SizedBox(
                  width: 5,
                ),
                _clearingKml
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3,color: ThemeColors.backgroundColor),
                      )
                    : const SizedBox()
              ],
            ),
          ),
          const SizedBox(height: 5,),
          ElevatedButton(
            onPressed: () async {
              checkLGConnection();
              if(!lgConnected){
                errorTaskButton();
              }else{

                if (_relaunching) {
                  return;
                }

                showDialog(
                  context: context,
                  builder: (context) => ConfirmDialog(
                    title: 'Are you sure?',
                    message: 'All screens will be relaunched.',
                    onCancel: () {
                      Navigator.of(context).pop();
                    },
                    onConfirm: () async {
                      Navigator.of(context).pop();

                      setState(() {
                        _relaunching = true;
                      });

                      try {
                        await _lgService.relaunch();
                      } finally {
                        setState(() {
                          _relaunching = false;
                        });
                      }
                    },
                  ),
                );
              }
            },
            style: _style,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buttonText('RELAUNCH'),
                const SizedBox(
                  width: 5,
                ),
                _relaunching
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3,color: ThemeColors.backgroundColor),
                      )
                    : const SizedBox()
              ],
            ),
          ),
          const SizedBox(height: 5,),
          ElevatedButton(
            onPressed: () async {
              checkLGConnection();
              if(!lgConnected){
                errorTaskButton();
              }else{

                if (_rebooting) {
                  return;
                }

                showDialog(
                  context: context,
                  builder: (context) => ConfirmDialog(
                    title: 'Are you sure?',
                    message: 'The system will be fully rebooted.',
                    onCancel: () {
                      Navigator.of(context).pop();
                    },
                    onConfirm: () async {
                      Navigator.of(context).pop();

                      setState(() {
                        _rebooting = true;
                      });

                      try {
                        await _lgService.reboot();
                      } finally {
                        setState(() {
                          _rebooting = false;
                        });
                      }
                    },
                  ),
                );
              }
            },
            style: _style,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buttonText('REBOOT'),
                const SizedBox(
                  width: 5,
                ),
                _rebooting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3,color: ThemeColors.backgroundColor),
                      )
                    : const SizedBox()
              ],
            ),
          ),
          const SizedBox(height: 5,),
          ElevatedButton(
            onPressed: () async {
              checkLGConnection();
              if(!lgConnected){
                errorTaskButton();
              }else{

                if (_shuttingDown) {
                  return;
                }

                showDialog(
                  context: context,
                  builder: (context) => ConfirmDialog(
                    title: 'Are you sure?',
                    message: 'The system will shutdown.',
                    onCancel: () {
                      Navigator.of(context).pop();
                    },
                    onConfirm: () async {
                      Navigator.of(context).pop();

                      setState(() {
                        _shuttingDown = true;
                      });

                      try {
                        await _lgService.shutdown();
                        // setState(() {
                        //   lgConnected = false;
                        // });
                      } finally {
                        setState(() {
                          _shuttingDown = false;
                        });
                      }
                    },
                  ),
                );
              }
            },
            style: _style,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buttonText('POWER OFF'),
                const SizedBox(
                  width: 5,
                ),
                _shuttingDown
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3,color: ThemeColors.backgroundColor),
                      )
                    : const SizedBox()
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buttonText(String text){
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: TextStyle(
            color: ThemeColors.backgroundColor,
            overflow: TextOverflow.visible,
            fontSize: 18,
            fontWeight: FontWeight.w400),
      ),
    );
  }

  void errorTaskButton(){
    showSnackbar(context, 'Please connect to LG rig.');
  }

}
