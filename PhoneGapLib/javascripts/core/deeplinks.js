PhoneGap.addConstructor(function() { if (typeof navigator.deeplink == "undefined") navigator.deeplink = new Deeplink(); });

/**
 * This class provides access to other applications and app store on the device.
 */
function Deeplink() {
	this.__callback = {};
}

Deeplink.prototype.open = function(url, callbackFnt) {
	this.__callback[url] = callbackFnt;
	PhoneGap.exec("Deeplink.open", url);
};

Deeplink.prototype.callback = function(url, successfull) {
	if (this.__callback[url]) {
		this.__callback[url](successfull);
	}
};
