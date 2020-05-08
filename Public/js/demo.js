const optimizeForm = document.getElementById("optimizeForm")
const slideComparison = document.getElementById("slideComparison")
const optimizedImage = document.getElementById("optimizedImage");
const originalFile = document.getElementById("originalFile");
const optimizedSize = document.getElementById("optimizedSize");
const originalSize = document.getElementById("originalSize");
const originalImage = document.getElementById("originalImage");
const downloadButton = document.getElementById("download");
const qualityField = document.getElementById("qualityField");
const errorWrapper = document.getElementById("errorWrapper");

function loadOriginalFile() {
    if(originalFile.files.length) {
        var reader = new FileReader();
        reader.onload = function(e) {
            originalImage.src = e.target.result;
        };
        reader.readAsDataURL(originalFile.files[0]);
        optimize()
    }
}

async function optimize(event) {
    var formData = new FormData(optimizeForm);
    const optimizeRequest = new Request('/demo/optimize/', {method: 'POST', body: formData});
    optimizedImage.classList.add("in-progress");
    qualityField.setAttribute("disabled", true);
    errorWrapper.innerText = "";

    fetch(optimizeRequest)
        .then(async response => {
            if (response.status !== 200) {
                var json = await response.json();
                throw new Error(json['reason'])
            }

            return response.json();
        })
        .then(json => {
            optimizedSize.innerText = Math.round(json["optimizedSize"] / 1024) + " kB";
            originalSize.innerText = Math.round(json["originalSize"] / 1024) + " kB";
            optimizedImage.src = "data:image/" + json["format"] + ";base64," + json["encodedImageData"];

            downloadButton.setAttribute("href", "data:" + json["format"] + ";base64," + json["encodedImageData"]);
            downloadButton.setAttribute("download", "quanta-" + optimizeForm.quality.value + "." + json["format"].split("/")[1]);
            downloadButton.style.display = "inline-block";

            slideComparison.style.width = originalImage.naturalWidth + "px";
            slideComparison.style.height = originalImage.naturalHeight + "px";

            slideComparison.style.display = "block";
        }).catch(error => {
            errorWrapper.innerText = error.toString();
            slideComparison.style.display = "none";
        }).finally(() => {
            window.dispatchEvent(new Event('resize'));
            optimizedImage.classList.remove("in-progress");
            qualityField.removeAttribute("disabled");
        });
}
