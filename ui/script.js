window.addEventListener('message', function(event) {
    if (event.data.action == 'open') {
        document.body.style.display = 'flex'; // Afficher l'UI avec flexbox pour centrer
    } else if (event.data.action == 'close') {
        document.body.style.display = 'none'; // Cacher l'UI
    }
});

// Gestion du clic sur le bouton "Louez Maintenant"
document.querySelectorAll('.vehicle button').forEach(function(button) {
    button.addEventListener('click', function() {
        let vehicleElement = this.parentElement;
        let model = vehicleElement.getAttribute('data-model');
        let price = vehicleElement.getAttribute('data-price');

        fetch(`https://${GetParentResourceName()}/rentVehicle`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                model: model,
                price: price
            })
        });

        // Fermer l'UI après la location
        document.body.style.display = 'none';
        fetch(`https://${GetParentResourceName()}/closeUI`, {
            method: 'POST'
        });
    });
});

// Gestion du clic sur le bouton de fermeture
document.getElementById('close-ui').addEventListener('click', function() {
    document.body.style.display = 'none';
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST'
    });
});