# Process to run a NIG interface

Process to intall and run a NIG interface based on Android Virtual Device to interact with a network of local Nodes
Technical details can be found here https://docs.google.com/document/d/e/2PACX-1vTO0nKIogxFLGWkN0QpaMsGsg9Cp-Aqfv31sc6p_HQnb7tShmqymOM05o3_7YCFkBY7GIipWSNO756d/pub

## Authors

- [@Crypto_NIG](https://github.com/nigcrypto)


## Instal Flutter

Install Fultter on your PC => https://docs.flutter.dev/get-started/install/windows/mobile

## Clone the project

```bash
  git clone https://github.com/project-nig/beta_interface.git
```

## Create a Virtual Device Manager
```bash
  Launch Android Studio
  Select More Actions
  Click on Virtual Device Manager
  Click on Create Device
  once created Click on the play button of this device
```
## Connect the Virtual Device Manager with Flutter
```bash
  Go to the directory below directoy where XXX is the name of your PC and launch this script
  C:\Users\XXXX\AppData\Local\Android\Sdk\platform-tools>adb reverse tcp:5000 tcp:5000

```

## Launch Visual Studio Code
```bash
  Go to the Menu Run and click on Start Debugging
```

## Play with the interface
```bash
  The debugging start may takes several minutes
  Your Android Virtual Device is now ready to interact with the network of local nodes 
```

## Feedback

If you have any feedback, please reach out to us at cryptomonnaie.nig@gmail.com

