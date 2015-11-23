//User ID Generation
var prefix = ['abc', 'def', 'ghi'],
    middle = ['123', '456', '789'],
    suffix = ['rst', 'uvw', 'xyz'],
    random = function() {
        return Math.floor(Math.random() * 3);
    };

function setCookie(cname, cvalue, exdays) {
    var d = new Date();
    d.setTime(d.getTime() + (exdays*24*60*60*1000));
    var expires = "expires="+d.toUTCString();
    document.cookie = cname + "=" + cvalue + "; " + expires;
}

function getCookie(cname) {
    var name = cname + "=";
    var ca = document.cookie.split(';');
    for(var i=0; i < ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1);
        if (c.indexOf(name) == 0) return c.substring(name.length, c.length);
    }
    return "";
}

var user = getCookie("username");
if (user == "") {
    var user = "User-" + prefix[random()] + '-' + Math.floor((Math.random() * 60000) + 1) + '-' + suffix[random()]; // e.g. abc-123-rst
    if (user != "" && user != null) {
        setCookie("username", user, 365);
    }
}

// Simple pseudo-random user id - 27 possible values
var customUserId = user; // e.g. abc-123-rst

(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
  ga('create', 'UA-29263631-1', 'auto');
  ga('create', 'UA-64842905-1', 'auto', {'name': 'newTracker'}, {'allowLinker': true },{'userId': customUserId});
  ga('newTracker.require', 'linker');
  ga('linker:autoLink', ['h2o.ai','leadpages.co']);
  ga('send', 'pageview');
  ga('newTracker.send', 'pageview');

  function getHitTime() {
    // Get local time as ISO string with offset at the end
    var now = new Date();
    var tzo = -now.getTimezoneOffset();
    var dif = tzo >= 0 ? '+' : '-';
    var pad = function(num) {
        var norm = Math.abs(Math.floor(num));
        return (norm < 10 ? '0' : '') + norm;
    };
    return now.getFullYear()
        + '-' + pad(now.getMonth()+1)
        + '-' + pad(now.getDate())
        + 'T' + pad(now.getHours())
        + ':' + pad(now.getMinutes())
        + ':' + pad(now.getSeconds())
        + '.' + pad(now.getMilliseconds())
        + dif + pad(tzo / 60)
        + ':' + pad(tzo % 60);
  }
  console.log(customUserId);
  ga(function(tracker) {
     ga('newTracker.set', 'dimension1', tracker.get('clientId'));
     ga('newTracker.set', 'dimension2', new Date().getTime() + '.' + Math.random().toString(36).substring(5));

  ga('newTracker.set', 'dimension3', getHitTime());
  ga('newTracker.set', 'dimension4', customUserId);

     ga('newTracker.send', 'pageview');
  });

