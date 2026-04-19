#include "flutter_vpn_plugin.h"

#include <flutter_plugin_windows.h>

#include <map>
#include <memory>
#include <sstream>

// This plain C++ plugin is only used as a stub for Windows
// Actual VPN implementation is done in Dart via windows_vpn_bridge.dart

class FlutterVpnPluginImpl : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(
      flutter::PluginRegistryWindows *registry);

  FlutterVpnPluginImpl();

  virtual ~FlutterVpnPluginImpl();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
          result);
};

void FlutterVpnPluginImpl::RegisterWithRegistrar(
    flutter::PluginRegistryWindows *registry) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registry->GetBinaryMessenger(), "flutter_vpn",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterVpnPluginImpl>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](
          const flutter::MethodCall<flutter::EncodableValue> &call,
          std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
              result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registry->AddPlugin(std::move(plugin));
}

FlutterVpnPluginImpl::FlutterVpnPluginImpl() {}

FlutterVpnPluginImpl::~FlutterVpnPluginImpl() {}

void FlutterVpnPluginImpl::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
        result) {
  // This plugin is a stub for Windows
  // All VPN functionality is implemented in Dart
  result->NotImplemented();
}
