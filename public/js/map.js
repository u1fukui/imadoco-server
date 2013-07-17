
function getPosition() {
  // 対応してるかチェック
  if (navigator.geolocation == undefined) {
    alert("位置情報の取得に未対応です。");
    return;
  }

  // 位置情報の取得
  navigator.geolocation.getCurrentPosition(successCallback, errorCallback);

  // 成功したとき
  function successCallback(position) {
    var lat = position.coords.latitude;
    var lng = position.coords.longitude;
    initializeMap(lat, lng)
    setPosition(lat, lng)
  }
  
  function setPosition(lat, lng) {
    var inputLat = document.getElementById("lat");
    inputLat.setAttribute("value", lat);

    var inputLng = document.getElementById("lng");
    inputLng.setAttribute("value", lng);
  }

  // 失敗したとき
  function errorCallback(err) {
    alert("位置情報の取得に失敗しました(" + err.code + ")" + err.message)
  }

  function initializeMap(lat, lng) {
    var latlng = new google.maps.LatLng(lat, lng);
    var myOptions = {
      zoom: 16,
      center: latlng,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    mapCanvas = new google.maps.Map(document.getElementById("map-canvas"), myOptions);

    var marker = new google.maps.Marker({
      position: latlng,
      map: mapCanvas,
      title:"今ここ！"
    });
    
    google.maps.event.addListener(mapCanvas, 'click', function(event) {
      //markerのpositionに値を設定する
      marker.setPosition(event.latLng);   //event.latLngでクリックしたところの緯度・経緯が取得できる
      setPosition(event.latLng.lat(), event.latLng.lng());
    }); 
  }
};

