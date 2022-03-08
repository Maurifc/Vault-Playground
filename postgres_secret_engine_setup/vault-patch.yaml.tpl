spec:
  template:
    spec:
      containers:
        - name: vault
          volumeMounts:
            - mountPath: /pgsql/${SECRET_NAME}
              name: ${SECRET_NAME}
              readOnly: true
      volumes:
        - name: ${SECRET_NAME}
          secret:
            defaultMode: 448
            secretName: ${SECRET_NAME}