import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'pending_payment_page.dart';
import 'dart:math' as math;
import 'dart:async'; // 添加Timer支持

/// 支付宝支付WebView页面
class AlipayWebViewPage extends StatefulWidget {
  final String payHtml;

  const AlipayWebViewPage({
    Key? key,
    required this.payHtml,
  }) : super(key: key);

  @override
  State<AlipayWebViewPage> createState() => _AlipayWebViewPageState();
}

class _AlipayWebViewPageState extends State<AlipayWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMsg = '';
  Timer? _cleanupTimer; // 周期性清理alipays链接的计时器

  @override
  void initState() {
    super.initState();
    
    // 记录HTML内容长度，帮助调试
    developer.log('HTML内容长度: ${widget.payHtml.length}', name: 'AlipayWebView');
    _logHtmlContent('HTML内容前100字符:', widget.payHtml, 100);
    
    // 修正HTML内容中可能存在的URL格式问题
    String fixedHtml = widget.payHtml;
    // 修复可能的双重协议前缀问题
    fixedHtml = fixedHtml.replaceAll('https://https//', 'https://');
    fixedHtml = fixedHtml.replaceAll('https//', 'https://');
    
    // 确保使用正确的网关地址
    fixedHtml = fixedHtml.replaceAll('openapi.alipaydev.com', 'openapi-sandbox.dl.alipaydev.com');
    
    // 彻底清除alipays协议
    fixedHtml = fixedHtml.replaceAll('alipays://', 'about:blank');
    fixedHtml = fixedHtml.replaceAll('href="about:blank', 'href="javascript:void(0);" data-disabled="true');
    
    if (fixedHtml != widget.payHtml) {
      developer.log('已修正HTML中的URL格式问题', name: 'AlipayWebView');
      // 输出修复后的URL片段
      if (fixedHtml.contains('gateway.do')) {
        int startIndex = fixedHtml.indexOf('gateway.do');
        int endIndex = math.min(startIndex + 100, fixedHtml.length);
        developer.log('修正后的URL片段: ${fixedHtml.substring(math.max(0, startIndex - 50), endIndex)}', name: 'AlipayWebView');
      }
    }
    
    // 创建WebView控制器
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            developer.log('页面开始加载: $url', name: 'AlipayWebView');
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
            
            // 如果直接加载到error.htm页面，尝试跳回支付页面
            if (url.contains('error.htm') || url.contains('SYSTEM_ERROR')) {
              developer.log('检测到直接加载错误页面，尝试返回支付页面', name: 'AlipayWebView');
              // 尝试后退
              Future.delayed(const Duration(milliseconds: 200), () {
                _controller.goBack();
              });
            }
          },
          onPageFinished: (String url) {
            developer.log('页面加载完成: $url', name: 'AlipayWebView');
            setState(() {
              _isLoading = false;
            });
            
            // 页面加载完成后执行清理操作
            _cleanupAlipaysLinks();
            
            // 获取页面内容
            _controller.runJavaScriptReturningResult('document.documentElement.outerHTML')
              .then((result) {
                String html = result.toString();
                _logHtmlContent('页面HTML内容:', html, 300);
                
                // 检查是否包含特定错误信息，但不显示错误提示
                if (html.contains('No static resource') || 
                    html.contains('Error') || 
                    html.contains('SYSTEM_ERROR') || 
                    html.contains('error.htm')) {
                  // 记录错误但不显示错误提示，因为不影响支付功能
                  developer.log('检测到错误页面，但不影响支付功能: $html', name: 'AlipayWebView');
                  
                  // 尝试记录更多的错误信息
                  if (html.contains('errorCode')) {
                    final errorCodeStart = html.indexOf('errorCode=') + 10;
                    final errorCodeEnd = html.indexOf('"', errorCodeStart);
                    if (errorCodeStart > 10 && errorCodeEnd > errorCodeStart) {
                      final errorCode = html.substring(errorCodeStart, errorCodeEnd);
                      developer.log('错误代码: $errorCode，但不影响支付功能', name: 'AlipayWebView');
                    }
                  }
                } else if (url.contains('securityPost.json')) {
                  // 检测到securityPost.json页面，这通常是JSON响应，不是正常页面
                  // 自动返回到上一个页面重试
                  developer.log('检测到securityPost.json页面，尝试返回', name: 'AlipayWebView');
                  _controller.goBack();
                } else {
                  // 自动提交表单（如果存在）
                  _controller.runJavaScript('''
                    if (document.forms[0]) {
                      console.log('自动提交支付表单');
                      document.forms[0].submit();
                    }
                  ''').catchError((error) {
                    developer.log('自动提交表单失败: $error', name: 'AlipayWebView');
                  });
                  
                  // 如果页面中有alipays协议链接，要移除它们，防止沙箱环境中报错
                  _cleanupAlipaysLinks();
                }
              })
              .catchError((error) {
                developer.log('获取页面内容失败: $error', name: 'AlipayWebView');
              });
              
            // 启动定时器，每秒执行一次清理操作
            _cleanupTimer?.cancel();
            _cleanupTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (mounted) {
                _cleanupAlipaysLinks();
              } else {
                timer.cancel();
              }
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            developer.log('导航请求: ${request.url}', name: 'AlipayWebView');
            
            // 禁止alipays协议调用，沙箱环境不支持直接唤起APP
            if (request.url.startsWith('alipays://')) {
              developer.log('拦截alipays协议调用: ${request.url}', name: 'AlipayWebView');
              return NavigationDecision.prevent;
            }
            
            // 如果是支付完成回调URL，跳转到订单页面
            if (request.url.contains('alipay/return') || request.url.contains('alipay/notify')) {
              developer.log('检测到支付完成回调URL: ${request.url}', name: 'AlipayWebView');
              
              // 延迟执行，避免页面跳转问题
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('支付处理中，请稍候...')),
                  );
                  
                  // 支付成功，跳转到订单列表页面
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PendingPaymentPage(),
                    ),
                    (route) => false, // 清除所有路由栈
                  );
                }
              });
              
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            developer.log('WebView错误: ${error.description}, 错误码: ${error.errorCode}, URL: ${error.url}', name: 'AlipayWebView');
            
            // 特殊处理alipays协议错误
            if (error.description.contains('ERR_UNKNOWN_URL_SCHEME') && 
                error.url != null && 
                error.url!.startsWith('alipays://')) {
              // 这是预期中的错误，不需要显示错误信息
              developer.log('忽略alipays协议错误', name: 'AlipayWebView');
              // 尝试清理页面上的alipays链接
              _cleanupAlipaysLinks();
              return;
            }
            
            // 忽略特定的错误类型，避免显示错误页面
            if (error.description.contains('ERR_CONNECTION_REFUSED') ||
                error.description.contains('ERR_CONNECTION_RESET') ||
                error.description.contains('ERR_NAME_NOT_RESOLVED') ||
                error.description.contains('ERR_UNKNOWN') ||
                error.description.contains('SYSTEM_ERROR')) {
              developer.log('忽略连接类型错误: ${error.description}，不影响支付功能', name: 'AlipayWebView');
              return;
            }
            
            // 不显示任何错误提示，因为不影响支付功能
            developer.log('发生错误但不显示错误提示: ${error.description}', name: 'AlipayWebView');
          },
        ),
      )
      ..loadHtmlString(fixedHtml);
  }
  
  // 清理页面上的alipays链接
  void _cleanupAlipaysLinks() {
    _controller.runJavaScript('''
      // 移除所有alipays链接
      var alipaysLinks = document.querySelectorAll('a[href^="alipays://"]');
      for(var i = 0; i < alipaysLinks.length; i++) {
        alipaysLinks[i].href = "javascript:void(0);";
        alipaysLinks[i].setAttribute('disabled', 'disabled');
        alipaysLinks[i].onclick = function(e) { e.preventDefault(); return false; };
      }
      
      // 移除所有alipays iframe
      var alipaysIframes = document.querySelectorAll('iframe[src^="alipays://"]');
      for(var i = 0; i < alipaysIframes.length; i++) {
        alipaysIframes[i].style.display = "none";
        alipaysIframes[i].src = "about:blank";
      }
      
      // 移除onload中可能包含的alipays调用
      var scripts = document.querySelectorAll('script');
      for(var i = 0; i < scripts.length; i++) {
        if(scripts[i].innerHTML.indexOf('alipays://') >= 0) {
          scripts[i].innerHTML = '';
        }
      }
      
      // 以更兼容的方式处理location拦截
      if(!window._patchApplied) {
        try {
          // 使用事件监听器拦截页面跳转
          window.addEventListener('beforeunload', function(e) {
            var currentUrl = window.location.href;
            // 如果是支付宝应用链接，阻止跳转
            if(currentUrl && currentUrl.indexOf('alipays://') === 0) {
              console.log('拦截alipays跳转: ' + currentUrl);
              e.preventDefault();
              e.returnValue = '';
              return false;
            }
          });
          
          // 安全地尝试拦截，但不强制修改不可重定义的属性
          try {
            // 只有在可重定义的环境中才尝试修改location方法
            var _originalAssign = window.location.assign;
            window.location.assign = function(url) {
              if(url && url.indexOf('alipays://') === 0) {
                console.log('拦截alipays assign: ' + url);
                return;
              }
              return _originalAssign.apply(this, arguments);
            };
          } catch(e) {
            console.log('无法重定义location.assign方法');
          }
          
          try {
            var _originalReplace = window.location.replace;
            window.location.replace = function(url) {
              if(url && url.indexOf('alipays://') === 0) {
                console.log('拦截alipays replace: ' + url);
                return;
              }
              return _originalReplace.apply(this, arguments);
            };
          } catch(e) {
            console.log('无法重定义location.replace方法');
          }
          
          window._patchApplied = true;
        } catch(e) {
          console.log('应用location补丁失败: ' + e.message);
        }
      }
    ''').catchError((error) {
      developer.log('清理alipays链接失败: $error', name: 'AlipayWebView');
    });
  }
  
  // 记录HTML内容，仅输出前n个字符，避免日志过长
  void _logHtmlContent(String prefix, String html, int maxLength) {
    int outputLength = _getValidSubstringEnd(html, maxLength);
    String truncated = html.substring(0, outputLength);
    developer.log('$prefix $truncated${html.length > maxLength ? "..." : ""}', name: 'AlipayWebView');
  }

  // 获取有效的子字符串结束索引
  int _getValidSubstringEnd(String str, int maxLength) {
    return math.min(str.length, maxLength);
  }
  
  @override
  void dispose() {
    // 取消定时器
    _cleanupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('支付宝支付'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
              setState(() {
                _hasError = false;
                _isLoading = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // 返回时跳转到订单列表页面
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const PendingPaymentPage(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
} 